import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { createRef } from "react";
import { describe, expect, it, vi } from "vitest";
import TextInput from "./TextInput";

describe("TextInput", () => {
    it("入力値の変更を親に伝える", async () => {
        const handleChange = vi.fn();
        render(<TextInput aria-label="Email" value="" onChange={handleChange} />);

        await userEvent.type(screen.getByLabelText("Email"), "a");

        expect(handleChange).toHaveBeenCalledOnce();
    });

    it("isFocused のときマウント時にフォーカスする", () => {
        render(<TextInput aria-label="Email" isFocused />);

        expect(screen.getByLabelText("Email")).toHaveFocus();
    });

    it("isFocused でないときはフォーカスしない", () => {
        render(<TextInput aria-label="Email" />);

        expect(screen.getByLabelText("Email")).not.toHaveFocus();
    });

    it("ref 経由で focus() を公開する", () => {
        const ref = createRef<{ focus: () => void }>();
        render(<TextInput aria-label="Email" ref={ref} />);

        ref.current?.focus();

        expect(screen.getByLabelText("Email")).toHaveFocus();
    });

    it("既定の type は text で、渡された className を保持する", () => {
        render(<TextInput aria-label="Email" className="w-full" />);

        const input = screen.getByLabelText("Email");

        expect(input).toHaveAttribute("type", "text");
        expect(input).toHaveClass("w-full");
    });
});
