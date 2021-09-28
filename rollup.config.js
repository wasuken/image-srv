import svelte from "rollup-plugin-svelte";
import resolve from "@rollup/plugin-node-resolve";

export default [
  {
	input: "src/index.js",
	output: {
      file: "public/js/index.bundle.js",
      format: "iife",
      name: "app",
	},
	plugins: [
      svelte({
		include: "src/**/*.svelte",
      }),
      resolve({browser: true}),
	],
  },
  {
	input: "src/post.js",
	output: {
      file: "public/js/post.bundle.js",
      format: "iife",
      name: "app",
	},
	plugins: [
      svelte({
		include: "src/**/*.svelte",
      }),
      resolve({browser: true}),
	],
  }
];
