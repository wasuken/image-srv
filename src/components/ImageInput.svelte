<script>
  import {inputImageUrls} from "../store.js";

  let inputUrl = "";

  function searchImgLinkInWebpage() {
    fetch(`/api/v1/img/in/page?url=${inputUrl}`)
      .then((r) => r.json())
      .then((j) => inputImageUrls.update((x) => j))
      .then((x) => (inputUrl = ""));
  }
  function clear() {
    inputImageUrls.update((x) => []);
  }
</script>

<div class="mb-3">
  <h3>Page内画像取得</h3>
  URL
  <input type="url" bind:value={inputUrl} />
  <button class="btn btn-primary" on:click={searchImgLinkInWebpage}>
    Page内取得
  </button>
  <button class="btn btn-secondary" on:click={clear}> 全て削除 </button>
</div>
