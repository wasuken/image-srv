<script>
  import {inputImageUrls} from "../store.js";

  let inputUrl = "";
  let promise = Promise.resolve([]);

  async function searchImgLinkInWebpage() {
    const resp = await fetch(`/api/v1/img/in/page?url=${inputUrl}`);
    if (resp.ok) {
      inputUrl = "";
      const json = await resp.json();
      const ja = json.map((x) => {
        return {url: x};
      });
      console.log(ja);
      inputImageUrls.update((x) => ja);
      return Promise.resolve({msg: "download ok"});
    } else {
      throw new Error("response error.");
    }
  }
  function clear() {
    inputImageUrls.update((x) => []);
  }
</script>

<div class="mb-3">
  <h3>Page内画像取得</h3>
  {#await promise}
    <p>...waiting</p>
  {:then rst}
    {#if rst.msg}
      <div class="result m-3">{rst.msg}</div>
    {/if}
  {:catch error}
    <p style="color: red">{error.message}</p>
  {/await}
  URL
  <input type="url" bind:value={inputUrl} />
  <button
    class="btn btn-primary"
    on:click={() => (promise = searchImgLinkInWebpage())}
  >
    Page内取得
  </button>
  <button class="btn btn-secondary" on:click={clear}> 全て削除 </button>
</div>
