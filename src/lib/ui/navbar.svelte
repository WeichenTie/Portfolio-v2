<script lang="ts">
  import { onMount } from 'svelte';
  import { throttle } from 'lodash';
  import scrollTo from '$lib/utils/scrollTo';
  import ScrambleText from '$lib/scramble-text/scramble-text.svelte';

  let display = true;

  function onClick(e: Event, id: string) {
    e.preventDefault();
    scrollTo(id);
  }

  onMount(() => {
    let scrollPos = 0;

    function onScroll(e: Event) {
      let newPos = document.documentElement.scrollTop;
      if (scrollPos > newPos) {
        display = true;
      } else {
        display = false;
      }
      scrollPos = newPos;
    }
    document.getElementById('navbar');
    window.addEventListener(
      'scroll',
      throttle((e) => onScroll(e), 150, { leading: false }),
    );
  });
</script>

<div id="navbar" class="nav-wrapper">
  <nav data-display={display}>
    <div class="main-container m-auto flex h-16  items-center gap-8 font-mono">
      <ScrambleText className="mr-auto">
        <a class="nav-item" href="/#">Weichen Tie</a>
      </ScrambleText>

      <ScrambleText>
        <a class="nav-item" on:click={(e) => onClick(e, 'about')} href="/#"
          >About</a>
      </ScrambleText>
      <ScrambleText>
        <a
          class="nav-item"
          on:click={(e) => onClick(e, 'experiments')}
          href="/#">Experiments</a>
      </ScrambleText>
      <ScrambleText>
        <a class="nav-item" on:click={(e) => onClick(e, 'skills')} href="/#"
          >Skills</a>
      </ScrambleText>
      <ScrambleText>
        <a class="nav-item" href="/#">Resume</a>
      </ScrambleText>
      <ScrambleText>
        <a class="nav-item" on:click={(e) => onClick(e, 'contact')} href="/#"
          >Contact Me</a>
      </ScrambleText>
    </div>
  </nav>
</div>

<style lang="postcss">
  @tailwind components;
  @layer components {
    .nav-wrapper {
      @apply fixed top-0 z-50 flex w-full text-xl text-white;
    }

    .nav-wrapper:hover > nav {
      @apply translate-y-0;
    }
    nav[data-display='true'] {
      @apply translate-y-0;
    }
    nav[data-display='false'] {
      @apply -translate-y-full;
    }
    nav {
      @apply w-full bg-black bg-opacity-70 font-primary transition-transform duration-300;
    }
    .nav-item:hover {
      @apply text-yellow-400;
    }
  }
</style>
