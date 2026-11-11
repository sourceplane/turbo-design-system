// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";

import { Button } from "@acme/ui/button";

// The library's component as a consumer gets it: the BUILT package export
// (`@acme/ui/button` → packages/ui/dist/button.mjs), as Storybook loads it.
afterEach(cleanup);

describe("Button (@acme/ui/button)", () => {
  it("renders its children in a button", () => {
    render(<Button>Hello</Button>);
    expect(screen.getByRole("button", { name: "Hello" }).tagName).toBe("BUTTON");
  });

  it("is type=button unless told otherwise", () => {
    render(<Button>Plain</Button>);
    expect(screen.getByRole("button", { name: "Plain" }).getAttribute("type")).toBe("button");
    cleanup();
    render(<Button type="submit">Send</Button>);
    expect(screen.getByRole("button", { name: "Send" }).getAttribute("type")).toBe("submit");
  });

  it("passes every other button attribute through", () => {
    const onClick = vi.fn();
    render(
      <Button onClick={onClick} style={{ color: "blue" }} aria-label="Go" disabled={false}>
        Go
      </Button>,
    );
    const button = screen.getByRole("button", { name: "Go" });
    expect(button.style.color).toBe("blue");
    fireEvent.click(button);
    expect(onClick).toHaveBeenCalledOnce();
  });

  it("is named Button in React's tools", () => {
    expect(Button.displayName).toBe("Button");
  });
});
