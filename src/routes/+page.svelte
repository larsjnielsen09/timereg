<script lang="ts">
  import { supabase } from '$lib/supabase';
  import { onMount } from 'svelte';

  let kunder: any[] = [];
  let sidsteOpgaver: any[] = [];
  
  let valgtKunde = '';
  let dato = new Date().toISOString().split('T')[0];
  let timer = '';
  let beskrivelse = '';
  let besked = '';

  onMount(async () => {
    await hentKunder();
    await hentSidsteOpgaver();
  });

  async function hentKunder() {
    const { data } = await supabase
      .from('kunder')
      .select('*')
      .order('navn');
    kunder = data ?? [];
    if (kunder.length > 0) valgtKunde = kunder[0].id;
  }

  async function hentSidsteOpgaver() {
    const { data } = await supabase
      .from('opgaver')
      .select('*, kunder(navn)')
      .order('dato', { ascending: false })
      .limit(5);
    sidsteOpgaver = data ?? [];
  }

  async function gemOpgave() {
    if (!valgtKunde || !dato || !timer) {
      besked = 'Udfyld venligst kunde, dato og timer.';
      return;
    }

    const { error } = await supabase.from('opgaver').insert({
      kunde_id: valgtKunde,
      dato: dato,
      timer: parseFloat(timer),
      beskrivelse: beskrivelse
    });

    if (error) {
      besked = 'Fejl: ' + error.message;
    } else {
      besked = '✅ Opgave gemt!';
      timer = '';
      beskrivelse = '';
      await hentSidsteOpgaver();
    }
  }

  function formaterDato(d: string) {
    const dato = new Date(d);
    return `${dato.getDate()}/${dato.getMonth() + 1}/${String(dato.getFullYear()).slice(2)}`;
  }
</script>

<div class="min-h-screen" style="background-color: #7fb3b0;">
  <div class="max-w-lg mx-auto p-4">

    <!-- Header -->
    <div class="text-center py-4 mb-6 rounded" style="background-color: #5a9a96;">
      <h1 class="text-3xl font-bold text-white">Opgaver</h1>
    </div>

    <!-- Navigation -->
    <div class="mb-4 text-right space-y-2">
      <div><a href="/oversigt" class="text-white underline">Se alle opgaver →</a></div>
      <div><a href="/kunder" class="text-white underline">Administrer kunder →</a></div>
    </div>

    <!-- Formular -->
    <div class="space-y-4 mb-8">
      <div>
        <label class="block text-gray-800 mb-1">Kunde</label>
        <select bind:value={valgtKunde} class="w-full p-3 rounded border border-gray-300 bg-white">
          {#each kunder as kunde}
            <option value={kunde.id}>{kunde.navn}</option>
          {/each}
        </select>
      </div>

      <div>
        <label class="block text-gray-800 mb-1">Dato</label>
        <input type="date" bind:value={dato}
          class="w-full p-3 rounded border border-gray-300 bg-white" />
      </div>

      <div>
        <label class="block text-gray-800 mb-1">Timer</label>
        <input type="number" bind:value={timer} placeholder="Timer" step="0.5" min="0"
          class="w-full p-3 rounded border border-gray-300 bg-white" />
      </div>

      <div>
        <label class="block text-gray-800 mb-1">Beskrivelse</label>
        <textarea bind:value={beskrivelse} placeholder="Beskrivelse" rows="4"
          class="w-full p-3 rounded border border-gray-300 bg-white resize-none"></textarea>
      </div>

      {#if besked}
        <p class="text-center font-semibold text-gray-800">{besked}</p>
      {/if}

      <div class="flex justify-center">
        <button on:click={gemOpgave}
          class="px-8 py-3 text-white font-bold rounded"
          style="background-color: #3a6b68;">
          GEM
        </button>
      </div>
    </div>

    <!-- Sidste 5 opgaver -->
    <div class="rounded overflow-hidden">
      <div class="py-4 text-center" style="background-color: #5a9a96;">
        <h2 class="text-2xl font-bold text-white">De sidste 5 opgaver</h2>
      </div>
      <div class="bg-white p-4 space-y-3">
        {#each sidsteOpgaver as opgave}
          <div class="border-b pb-3">
            <p>
              <strong>{opgave.kunder?.navn}</strong>,
              Dato: {formaterDato(opgave.dato)},
              Timer: {opgave.timer},
            </p>
            <p>
              <span class="underline">Beskrivelse:</span>
              {opgave.beskrivelse ?? ''}
            </p>
          </div>
        {/each}
      </div>
    </div>

  </div>
</div>