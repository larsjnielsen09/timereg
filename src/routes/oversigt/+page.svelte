<script lang="ts">
  import { supabase } from '$lib/supabase';
  import { onMount } from 'svelte';

  let kunder: any[] = [];
  let opgaver: any[] = [];
  let filtreretOpgaver: any[] = [];

  let valgtKunde = 'alle';
  let fraDato = '';
  let tilDato = '';
  let totalTimer = 0;

  let redigerOpgaveId: number | null = null;
  let sletOpgaveId: number | null = null;
  let redigerKundeId = '';
  let redigerDato = '';
  let redigerTimer = '';
  let redigerBeskrivelse = '';
  let redigerBesked = '';

  onMount(async () => {
    await hentKunder();
    await hentOpgaver();
  });

  async function hentKunder() {
    const { data } = await supabase
      .from('kunder')
      .select('*')
      .order('navn');
    kunder = data ?? [];
  }

  async function hentOpgaver() {
    const { data } = await supabase
      .from('opgaver')
      .select('*, kunder(navn)')
      .order('dato', { ascending: false });
    opgaver = data ?? [];
    filtrer();
  }

  function filtrer() {
    filtreretOpgaver = opgaver.filter(o => {
      const kundeMatch = valgtKunde === 'alle' || o.kunde_id === parseInt(valgtKunde);
      const fraMatch = !fraDato || o.dato >= fraDato;
      const tilMatch = !tilDato || o.dato <= tilDato;
      return kundeMatch && fraMatch && tilMatch;
    });
    totalTimer = filtreretOpgaver.reduce((sum, o) => sum + parseFloat(o.timer), 0);
  }

  function formaterDato(d: string) {
    const dato = new Date(d);
    return `${dato.getDate()}/${dato.getMonth() + 1}/${String(dato.getFullYear()).slice(2)}`;
  }

  function nulstil() {
    valgtKunde = 'alle';
    fraDato = '';
    tilDato = '';
    filtrer();
  }

  function startRediger(opgave: any) {
    redigerOpgaveId = opgave.id;
    sletOpgaveId = null;
    redigerKundeId = opgave.kunde_id;
    redigerDato = opgave.dato;
    redigerTimer = opgave.timer.toString();
    redigerBeskrivelse = opgave.beskrivelse ?? '';
  }

  function annullerRediger() {
    redigerOpgaveId = null;
    redigerBesked = '';
  }

  async function gemRediger() {
    const { error } = await supabase
      .from('opgaver')
      .update({
        kunde_id: redigerKundeId,
        dato: redigerDato,
        timer: parseFloat(redigerTimer),
        beskrivelse: redigerBeskrivelse
      })
      .eq('id', redigerOpgaveId);

    if (error) {
      redigerBesked = 'Fejl ved opdatering: ' + error.message;
    } else {
      redigerOpgaveId = null;
      await hentOpgaver();
    }
  }

  function bekræftSlet(opgave: any) {
    sletOpgaveId = opgave.id;
    redigerOpgaveId = null;
  }

  function annullerSlet() {
    sletOpgaveId = null;
  }

  async function sletOpgave() {
    const { error } = await supabase
      .from('opgaver')
      .delete()
      .eq('id', sletOpgaveId);

    if (error) {
      redigerBesked = 'Fejl ved sletning: ' + error.message;
      sletOpgaveId = null;
    } else {
      sletOpgaveId = null;
      await hentOpgaver();
    }
  }
</script>

<div class="min-h-screen" style="background-color: #7fb3b0;">
  <div class="max-w-2xl mx-auto p-4">

    <!-- Header -->
    <div class="text-center py-4 mb-6 rounded" style="background-color: #5a9a96;">
      <h1 class="text-3xl font-bold text-white">Oversigt</h1>
    </div>

    <!-- Tilbage knap -->
    <div class="mb-4">
      <a href="/" class="text-white underline">← Tilbage til registrering</a>
    </div>

    <!-- Kunde administration -->
    <div class="mb-4">
      <a href="/kunder" class="text-white underline">Administrer kunder →</a>
    </div>

    <!-- Filtrering -->
    <div class="bg-white rounded p-4 mb-6 space-y-3">
      <div>
        <label class="block text-gray-700 mb-1">Kunde</label>
        <select bind:value={valgtKunde} on:change={filtrer}
          class="w-full p-3 rounded border border-gray-300">
          <option value="alle">Alle kunder</option>
          {#each kunder as kunde}
            <option value={kunde.id}>{kunde.navn}</option>
          {/each}
        </select>
      </div>

      <div class="flex gap-3">
        <div class="flex-1">
          <label class="block text-gray-700 mb-1">Fra dato</label>
          <input type="date" bind:value={fraDato} on:change={filtrer}
            class="w-full p-3 rounded border border-gray-300" />
        </div>
        <div class="flex-1">
          <label class="block text-gray-700 mb-1">Til dato</label>
          <input type="date" bind:value={tilDato} on:change={filtrer}
            class="w-full p-3 rounded border border-gray-300" />
        </div>
      </div>

      <button on:click={nulstil}
        class="px-4 py-2 text-white rounded text-sm"
        style="background-color: #3a6b68;">
        Nulstil filter
      </button>
    </div>

    <!-- Total -->
    <div class="bg-white rounded p-4 mb-4 flex justify-between items-center">
      <span class="font-bold text-gray-700">
        {filtreretOpgaver.length} opgaver
      </span>
      <span class="font-bold text-gray-700">
        Total: {totalTimer.toFixed(1)} timer
      </span>
    </div>

    <!-- Opgaveliste -->
    <div class="bg-white rounded overflow-hidden">
      {#each filtreretOpgaver as opgave}
        <div class="p-4 border-b last:border-b-0">
          {#if redigerOpgaveId === opgave.id}
            <!-- Inline edit form -->
            <div class="space-y-3">
              <div>
                <label class="block text-gray-700 mb-1">Kunde</label>
                <select bind:value={redigerKundeId}
                  class="w-full p-2 rounded border border-gray-300 bg-white text-sm">
                  {#each kunder as kunde}
                    <option value={kunde.id}>{kunde.navn}</option>
                  {/each}
                </select>
              </div>

              <div class="flex gap-3">
                <div class="flex-1">
                  <label class="block text-gray-700 mb-1">Dato</label>
                  <input type="date" bind:value={redigerDato}
                    class="w-full p-2 rounded border border-gray-300 bg-white text-sm" />
                </div>
                <div class="flex-1">
                  <label class="block text-gray-700 mb-1">Timer</label>
                  <input type="number" bind:value={redigerTimer} step="0.5" min="0"
                    class="w-full p-2 rounded border border-gray-300 bg-white text-sm" />
                </div>
              </div>

              <div>
                <label class="block text-gray-700 mb-1">Beskrivelse</label>
                <textarea bind:value={redigerBeskrivelse} rows="2"
                  class="w-full p-2 rounded border border-gray-300 bg-white text-sm resize-none"></textarea>
              </div>

              {#if redigerBesked}
                <p class="text-red-600 text-sm">{redigerBesked}</p>
              {/if}

              <div class="flex gap-2">
                <button on:click={gemRediger}
                  class="px-4 py-2 text-white rounded text-sm"
                  style="background-color: #3a6b68;">
                  Gem
                </button>
                <button on:click={annullerRediger}
                  class="px-4 py-2 text-gray-700 rounded text-sm border border-gray-300">
                  Annuller
                </button>
              </div>
            </div>
          {:else}
            <!-- Normal row display -->
            <div style="display: grid; grid-template-columns: 1fr auto;">
              <p class="font-bold">{opgave.kunder?.navn}</p>
              <div class="flex items-center gap-1">
                <span class="font-bold text-lg">{opgave.timer} timer</span>
                <button on:click={() => startRediger(opgave)}
                  class="p-1 text-gray-400 hover:text-gray-700"
                  title="Rediger">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                  </svg>
                </button>
                <button on:click={() => bekræftSlet(opgave)}
                  class="p-1 text-gray-400 hover:text-red-600"
                  title="Slet">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            </div>
            <p class="text-sm text-gray-500">{formaterDato(opgave.dato)}</p>
            <p class="mt-1">{opgave.beskrivelse ?? ''}</p>

            <!-- Delete confirmation -->
            {#if sletOpgaveId === opgave.id}
              <div class="mt-2 p-2 bg-red-50 rounded flex items-center justify-between">
                <span class="text-sm text-red-700">Slet denne opgave?</span>
                <div class="flex gap-2">
                  <button on:click={sletOpgave}
                    class="px-3 py-1 text-white text-sm rounded bg-red-600 hover:bg-red-700">
                    Ja
                  </button>
                  <button on:click={annullerSlet}
                    class="px-3 py-1 text-gray-700 text-sm rounded border border-gray-300">
                    Nej
                  </button>
                </div>
              </div>
            {/if}
          {/if}
        </div>
      {/each}

      {#if filtreretOpgaver.length === 0}
        <p class="p-4 text-gray-500 text-center">Ingen opgaver fundet</p>
      {/if}
    </div>

  </div>
</div>
