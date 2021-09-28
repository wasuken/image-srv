<script>
  import Header from "./components/Header.svelte";
  import TagInput from "./components/TagInput.svelte";
  import ImageList from "./components/ImageList.svelte";
  import {inputImageUrls, inputTags} from "./store.js";

  let promise = Promise.resolve([]);
  async function postImages() {
    const body = {
      urls: $inputImageUrls,
      tags: $inputTags,
    };
    const resp = await fetch("/api/v1/images", {
      method: "POST",
      mode: "cors",
      cache: "no-cache",
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    if (resp.ok) {
      return resp.json();
    } else {
      throw new Error("Invalid Response.");
    }
  }
</script>

<Header />

<div class="m-3">
  {#await promise}
    <div>waiting...</div>
  {:then data}
    <div />
  {:catch error}
    <p style="color: red">{error.message}</p>
  {/await}

  <TagInput />

  <ImageList readonly={false} />

  <div class="mb-3">
    <button class="btn btn-primary" on:click={postImages}> 登録 </button>
  </div>
</div>
