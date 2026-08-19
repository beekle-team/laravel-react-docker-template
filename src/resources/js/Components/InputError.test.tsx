import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import InputError from "./InputError";

describe("InputError", () => {
    it("message があるとエラーを表示する", () => {
        render(<InputError message="メールアドレスの形式が正しくありません" />);

        expect(screen.getByText("メールアドレスの形式が正しくありません")).toBeInTheDocument();
    });

    it("message がないと何も描画しない", () => {
        const { container } = render(<InputError />);

        expect(container).toBeEmptyDOMElement();
    });
});
