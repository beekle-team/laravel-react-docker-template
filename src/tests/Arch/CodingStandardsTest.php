<?php

declare(strict_types=1);

// .ai/rules/php.md の型宣言・strict types ルールを実行可能な形にした検査。

arch('アプリケーションコードは strict types を宣言する')
    ->expect('App')
    ->toUseStrictTypes();

arch('テストコードも strict types を宣言する')
    ->expect('Tests')
    ->toUseStrictTypes();
