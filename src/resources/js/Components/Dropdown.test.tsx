import { render, screen, waitForElementToBeRemoved } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import Dropdown from "./Dropdown";

function renderDropdown() {
    return render(
        <Dropdown>
            <Dropdown.Trigger>
                <button type="button">メニュー</button>
            </Dropdown.Trigger>
            <Dropdown.Content>
                <span>ログアウト</span>
            </Dropdown.Content>
        </Dropdown>,
    );
}

describe("Dropdown", () => {
    it("初期状態では内容を表示しない", () => {
        renderDropdown();

        expect(screen.queryByText("ログアウト")).not.toBeInTheDocument();
    });

    it("トリガーをクリックすると内容を表示する", async () => {
        renderDropdown();

        await userEvent.click(screen.getByRole("button", { name: "メニュー" }));

        expect(screen.getByText("ログアウト")).toBeVisible();
    });

    it("内容をクリックすると閉じる", async () => {
        renderDropdown();

        await userEvent.click(screen.getByRole("button", { name: "メニュー" }));
        const item = screen.getByText("ログアウト");
        await userEvent.click(item);

        // Transition の leave アニメーションが終わるまで DOM に残るため、削除を待つ。
        await waitForElementToBeRemoved(item);
    });
});
