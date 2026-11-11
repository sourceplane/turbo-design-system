// @vitest-environment jsdom
import { afterEach, describe, expect, it } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { composeStories } from "@storybook/react-vite";

import * as stories from "@/stories/button.stories";

// The template's stories, run as Storybook runs them (portable stories: each
// story composed with its meta's args and argTypes), in jsdom.
afterEach(cleanup);
const { Primary } = composeStories(stories);

describe("the button stories (apps/docs/stories/button.stories.tsx)", () => {
  it("documents the library's Button, with autodocs", () => {
    expect(stories.default.component).toBeDefined();
    expect(stories.default.component?.displayName).toBe("Button");
    expect(stories.default.tags).toEqual(["autodocs"]);
  });

  it("offers the button's type as a radio control", () => {
    expect(stories.default.argTypes?.type).toEqual({
      control: { type: "radio" },
      options: ["button", "submit", "reset"],
    });
  });

  it("has one story, exported as Primary and shown as Button", () => {
    expect(Object.keys(stories).sort()).toEqual(["Primary", "default"]);
    expect(stories.Primary.name).toBe("Button");
  });

  it("renders the story: Hello, type=button, the template's inline style", () => {
    render(<Primary />);
    const button = screen.getByRole("button", { name: "Hello" });
    expect(button.getAttribute("type")).toBe("button");
    expect(button.style.color).toBe("blue");
    expect(button.style.border).toBe("1px solid gray");
    expect(button.style.padding).toBe("10px");
    expect(button.style.borderRadius).toBe("10px");
  });

  it("spies on clicks with the meta's action (fn())", () => {
    render(<Primary />);
    fireEvent.click(screen.getByRole("button", { name: "Hello" }));
    expect(Primary.args.onClick).toHaveBeenCalledOnce();
  });

  it("re-renders from new args, as a control does", () => {
    render(<Primary children="Click me" type="submit" />);
    expect(screen.getByRole("button", { name: "Click me" }).getAttribute("type")).toBe("submit");
  });
});
