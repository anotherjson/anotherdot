---
name: component-creator
description: A skill to create boilerplate code for new Svelte, Python, or Rust components.
---
# Skill: Component Creator

## Instructions

1.  **Ask for details:** Ask the user for the following information:
    -   The name of the component (e.g., `MyComponent`, `user_service`).
    -   The programming language (e.g., `Svelte`, `Python`, `Rust`).
    -   The directory where the component should be created.
2.  **Generate boilerplate:** Based on the language, generate a basic boilerplate file.
    -   For **Svelte**, create a Svelte component (`.svelte` file) with a `<script lang="ts">` block and basic Tailwind CSS classes.
    -   For **Python**, create a simple class, remembering to use modern type hints.
    -   For **Rust**, create a new file with a public struct or function.
3.  **Create the file:** Create a new file with the appropriate name and extension (e.g., `MyComponent.svelte`, `user_service.py`, `my_module.rs`) in the specified directory.
4.  **Inform the user:** Let the user know that the component has been created, and show them the path to the new file.
