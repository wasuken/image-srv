<script>
  import {inputImageUrls} from "../store.js";
  import ImageInput from "./ImageInput.svelte";

  export let readonly = true;
  let urlInput = "";
  let promise = Promise.resolve([]);

  function add() {
    let urls = $inputImageUrls;
    let iUrls = urlInput
      .replace(" ", "")
      .split(",")
      .filter((x) => x.length > 0);
    let newUrls = new Set([...urls, ...iUrls]);
    inputImageUrls.set(Array.from(newUrls));
  }
  const sharo_delete = function (url) {
    let urls = $inputImageUrls.filter((x) => x !== url);
    inputImageUrls.set([...urls]);
  };
  const force_delete = async function (url) {
    const response = await fetch(`/api/v1/image/url=${url}`, {
      method: "DELETE",
    });

    if (response.ok) {
      return response.json();
    } else {
      throw new Error(url);
    }
  };
  let del = sharo_delete;
  if (readonly) {
    del = (url) => (promise = force_delete(url.url));
  }
</script>

<div>
  <h3>画像一覧</h3>
  {#await promise}
    <p />
  {:then resp}
    {#if resp.msg}
      <div class="result">{resp.msg}</div>
    {/if}
  {:catch error}
    <p style="color: red">{error.message}</p>
  {/await}
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
          {#if readonly}
            <hr />
            width: {url.width}, height: {url.height}, size: {url.bytesize}
            <hr />
            tags:
            <div class="d-flex justify-content-start">
              {#each url.tags as tag}
                <div class="text-wrap mx-1">
                  {tag}
                </div>
              {/each}
            </div>
            <hr />
            <a href={url.url} class="btn btn-primary" download> Download </a>
          {/if}
          <button class="btn btn-secondary" on:click={() => del(url)}>
            削除
          </button>
        </figcaption>
      </figure>
    {/each}
  </div>
</div>
