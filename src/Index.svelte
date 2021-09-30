<script>
  import Header from "./components/Header.svelte";
  import TagInput from "./components/TagInput.svelte";
  import ImageList from "./components/ImageList.svelte";
  import {inputImageUrls} from "./store.js";

  let promise = Promise.resolve([]);
  async function searchImages() {
    const resp = await fetch("/api/v1/images");
    if (resp.ok) {
      return resp.json();
    } else {
      throw new Error("Invalid Response.");
    }
  }
  function topImages() {
    fetch("/api/v1/images/top")
      .then((x) => x.json())
      .then((j) => {
        let urls = [];
        let tags = [];
        inputImageUrls.set(j.map((x) => x));
      });
  }
  topImages();
</script>

<Header />

<div class="m-3">
  <TagInput />

  <div>
    <button class="btn btn-primary"> 検索 </button>
  </div>

  <ImageList />
</div>
