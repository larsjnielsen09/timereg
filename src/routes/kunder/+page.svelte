<script lang="ts">
  import { supabase } from '$lib/supabase';
  import { onMount } from 'svelte';

  let kunder: any[] = [];
  let nyKundeNavn = '';
  let besked = '';
  let redigerKundeId: number | null = null;
  let redigerNavn = '';
  let sletKundeId: number | null = null;

  onMount(async () => {
    await hentKunder();
  });

  async function hentKunder() {
    const { data } = await supabase
      .from('kunder')
      .select('*')
      .order('navn');
    kunder = data ?? [];
  }

  async function tilfoejKunde() {
    if (!nyKundeNavn.trim()) {
      besked = 'Udfyld venligst kundenavn';
      return;
    }

    const { error } = await supabase.from('kunder').insert({
      navn: nyKundeNavn.trim()
    });

    if (error) {
      besked = 'Fejl: ' + error.message;
    } else {
      besked = '✅ Kunde oprettet!';
      nyKundeNavn = '';
      await hentKunder();
    }
  }

  function startRediger(kunde: any) {
    redigerKundeId = kunde.id;
    redigerNavn = kunde.navn;
    sletKundeId = null;
  }

  function annullerRediger() {
    redigerKundeId = null;
    besked = '';
  }

  async function gemRediger() {
    if (!redigerNavn.trim()) {
      besked = 'Udfyld venligst kundenavn';
      return;
    }

    const { error } = await supabase
      .from('kunder')
      .update({
        navn: redigerNavn.trim()
      })
      .eq('id', redigerKundeId);

    if (error) {
      besked = 'Fejl ved opdatering: ' + error.message;
    } else {
      redigerKundeId = null;
      await hentKunder();
    }
  }

  function bekraeftSlet(kunde: any) {
    sletKundeId = kunde.id;
    redigerKundeId = null;
  }

  function annullerSlet() {
    sletKundeId = null;
  }

  async function sletKunde() {
    const { error } = await supabase
      .from('kunder')
      .delete()
      .eq('id', sletKundeId);

    if (error) {
      if (error.message.includes('foreign key')) {
        besked = 'Kan ikke slette kunde med tilknyttede opgaver';
      } else {
        besked = 'Fejl ved sletning: ' + error.message;
      }
      sletKundeId = null;
    } else {
      sletKundeId = null;
      await hentKunder();
    }
  }
</script>

<div class="min-h-screen" style="background-color: #7fb3b0;">
  <div class="max-w-2xl mx-auto p-4">

    <!-- Header -->
    <div class="text-center py-4 mb-6 rounded" style="background-color: #5a9a96;">
      <h1 class="text-3xl font-bold text-white">Kunder</h1>
    </div>

    <!-- Tilbage knap -->
    <div class="mb-4">
      <a href="/" class="text-white underline">← Tilbage til registrering</a>
    </div>

    <!-- Create form -->
    <div class="bg-white rounded p-4 mb-6 space-y-3">
      <div>
        <label class="block text-gray-700 mb-1">Nyt kundenavn</label>
        <input type="text" bind:value={nyKundeNavn}
          class="w-full p-3 rounded border border-gray-300" />
      </div>

      {#if besked}
        <p class="text-center font-semibold text-gray-800">{besked}</p>
      {/if}

      <button on:click={tilfoejKunde}
        class="px-4 py-2 text-white rounded text-sm"
        style="background-color: #3a6b68;">
        Tilføj kunde
      </button>
    </div>

    <!-- Customer list -->
    <div class="bg-white rounded overflow-hidden">
      {#each kunder as kunde}
        <div class="p-4 border-b last:border-b-0">
          {#if redigerKundeId === kunde.id}
            <!-- Inline edit form -->
            <div class="space-y-3">
              <div>
                <label class="block text-gray-700 mb-1">Kundenavn</label>
                <input type="text" bind:value={redigerNavn}
                  class="w-full p-2 rounded border border-gray-300 bg-white text-sm" />
              </div>

              {#if besked}
                <p class="text-red-600 text-sm">{besked}</p>
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
              <p class="font-bold">{kunde.navn}</p>
              <div class="flex items-center gap-1">
                <button on:click={() => startRediger(kunde)}
                  class="p-1 text-gray-400 hover:text-gray-700"
                  title="Rediger">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                  </svg>
                </button>
                <button on:click={() => bekraeftSlet(kunde)}
                  class="p-1 text-gray-400 hover:text-red-600"
                  title="Slet">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            </div>

            <!-- Delete confirmation -->
            {#if sletKundeId === kunde.id}
              <div class="mt-2 p-2 bg-red-50 rounded flex items-center justify-between">
                <span class="text-sm text-red-700">Slet denne kunde?</span>
                <div class="flex gap-2">
                  <button on:click={sletKunde}
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

      {#if kunder.length === 0}
        <p class="p-4 text-gray-500 text-center">Ingen kunder fundet</p>
      {/if}
    </div>

  </div>
</div>
