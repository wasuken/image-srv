<script>
  import Header from "./components/Header.svelte";
  import TagInput from "./components/TagInput.svelte";
  import ImageList from "./components/ImageList.svelte";
  import {inputTags, searchResult, inputImageUrls} from "./store.js";

  let order = "desc";
  let page = 1;
  let limit = 10;
  let max_page = 0;
  async function searchImages() {
    const tags_q = $inputTags.map((x) => `tags[]=${x}`).join("&");
    const query = `page=${page}&limit=${limit}&${tags_q}`;
    const resp = await fetch(`/api/v1/images/search?${query}`);
    if (resp.ok) {
      const j = await resp.json();
      max_page = j.page_size;
      page = j.page;
      const ja = j.data;
      inputImageUrls.update((x) => ja);
      return Promise.resolve({msg: "search ok"});
    } else {
      throw new Error("search request error.");
    }
  }
  searchImages();
</script>

<Header />

<div class="m-3">
  <!-- options -->
  <div class="m-3">
    <h3>Options</h3>
    <div class="mb-3">
      取得件数: <input type="number" bind:value={limit} />
      並び:
      <select bind:value={order}>
        <option value="asc">昇順</option>
        <option value="desc">降順</option>
      </select>
    </div>
    <div class="mb-3">
      <select bind:value={page}>
        {#each Array.from(Array(max_page), (v, k) => k) as i, j}
          <option value={j + 1}>
            {j + 1}
          </option>
        {/each}
      </select>
    </div>
  </div>
  <TagInput />

  <div>
    <button class="btn btn-primary" on:click={searchImages}> 検索 </button>
  </div>

  <ImageList />
</div>
