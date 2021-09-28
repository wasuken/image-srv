<script>
  import {inputImageUrls} from "../store.js";
  export let readonly = true;
  let urlInput = "";
  function add() {
    let urls = $inputImageUrls;
    let iUrls = urlInput
      .replace(" ", "")
      .split(",")
      .filter((x) => x.length > 0);
    let newUrls = new Set([...urls, ...iUrls]);
    inputImageUrls.set(Array.from(newUrls));
  }
  function del(url) {
    let urls = $inputImageUrls.filter((x) => x !== url);
    inputImageUrls.set([...urls]);
  }
</script>

<div class="mb-3">
  <div class="container-fluid">
    {#each $inputImageUrls as url}
      <div class="row">
        <div class="col-4">
          <div>
            {url}
          </div>
          <div>
            <img src={url} height="300px" />
          </div>
          <div>
            <button class="btn btn-secondary" on:click={() => del(url)}>
              削除
            </button>
          </div>
        </div>
      </div>
    {/each}
  </div>
  {#if !readonly}
    <div class="mb-3">
      <input type="url" bind:value={urlInput} />
      <button class="btn btn-primary" on:click={add}> 追加 </button>
    </div>
  {/if}
</div>
