<script>
  import {inputTags} from "../store.js";
  let tagInput = "";
  function add(tag) {
    if (tag.length > 100) return;
    let tags = $inputTags;
    let iTags = tagInput
      .replace(" ", "")
      .split(",")
      .filter((x) => x.length > 0);
    let newTags = new Set([...tags, ...iTags]);
    inputTags.set(Array.from(newTags));
    tagInput = "";
  }
  function del(tag) {
    let tags = $inputTags.filter((x) => x !== tag);
    inputTags.set([...tags]);
  }
</script>

<div class="mb-3">
  <div class="container-fluid">
    <div class="row">
      <h3>Tag入力</h3>
    </div>
    <div class="row">
      {#each $inputTags as tag}
        <div class="col-2">
          <div class="text-wrap">
            {tag}
          </div>
          <button class="btn btn-secondary" on:click={() => del(tag)}>
            削除
          </button>
        </div>
      {/each}
    </div>
  </div>
  <div class="mb-3">
    <input type="text" bind:value={tagInput} />
    <button class="btn btn-primary" on:click={add}> 追加 </button>
  </div>
</div>
