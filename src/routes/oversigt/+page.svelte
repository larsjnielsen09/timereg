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
            <div style="display: grid; grid-template-columns: 1fr auto;">
            <p class="font-bold">{opgave.kunder?.navn}</p>
            <span class="font-bold text-lg">{opgave.timer} timer</span>
            </div>
            <p class="text-sm text-gray-500">{formaterDato(opgave.dato)}</p>
            <p class="mt-1">{opgave.beskrivelse ?? ''}</p>
        </div>
        {/each}

      {#if filtreretOpgaver.length === 0}
        <p class="p-4 text-gray-500 text-center">Ingen opgaver fundet</p>
      {/if}
    </div>

  </div>
</div>
