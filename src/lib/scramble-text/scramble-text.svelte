<script lang="ts">
  import { onMount } from 'svelte';

  let ref: HTMLElement;
  const LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  onMount(() => {
    const controller = new AbortController();
    const child = ref.firstChild as ChildNode;
    if (!ref?.firstChild?.textContent) return;
    const originalText = child.textContent;
    // Scramble effect
    ref.addEventListener(
      'mouseover',
      (e) => {
        let iterations = 0;
        const interval = setInterval(() => {
          const randomText = originalText!
            .split('')
            .map((letter) => letter === ' ' ? ' ' : LETTERS[Math.floor(Math.random() * 26 * 2)])
            .join('');
          child.textContent =
            originalText!.slice(0, iterations) +
            randomText.slice(iterations, originalText!.length);
          if (iterations > originalText!.length) {
            child.textContent = originalText;
            clearInterval(interval);
          }
          iterations += 1 / 3;
        }, 30);

        return () => {
          controller.abort();
        };
      },
      {
        signal: controller.signal,
      },
    );
  });

  export let className = '';
</script>

<span bind:this={ref} class={className}>
  <slot />
</span>
