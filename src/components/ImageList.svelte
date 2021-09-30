<script>
  import {inputImageUrls} from "../store.js";
  import ImageInput from "./ImageInput.svelte";
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

<div>
  <h3>画像一覧</h3>
  <div class="imagearea">
    {#if !readonly}
      <div class="mb-3">
        <input type="url" bind:value={urlInput} />
        <button class="btn btn-primary" on:click={add}> 追加 </button>
      </div>
      <div class="m-3">
        <ImageInput />
      </div>
    {/if}
    {#each $inputImageUrls as url}
      <figure class="m-3">
        <img alt="" src={url.url} height="200" />
        <figcaption>
          <hr />
          width: {url.width}, height: {url.height}, size: {url.bytesize}
          <hr />
          tags:
          <div class="row">
            {#each url.tags as tag}
              <div class="col-6">
                <div class="text-wrap">
                  {tag}
                </div>
              </div>
            {/each}
          </div>
          <hr />
          <button class="btn btn-secondary" on:click={() => del(url)}>
            削除
          </button>
          <a href={url.url} class="btn btn-primary" download> Download </a>
        </figcaption>
      </figure>
    {/each}
  </div>
</div>
