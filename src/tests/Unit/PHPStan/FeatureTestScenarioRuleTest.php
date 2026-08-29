<?php

declare(strict_types=1);

use Symfony\Component\Process\Process;

it('Feature テストは scenario ヘルパーを使う', function (): void {
    $process = new Process([
        PHP_BINARY,
        base_path('vendor/bin/phpstan'),
        'analyse',
        base_path('tests/Feature/PHPStanFixtures/ClassStyleFeatureTest.php.inc'),
        base_path('tests/Feature/PHPStanFixtures/PestStyleFeatureTest.php.inc'),
        '--configuration='.base_path('tests/PHPStan/phpstan-fixtures.neon'),
        '--error-format=raw',
        '--no-progress',
        '--no-ansi',
        '--memory-limit=1G',
    ]);
    $process->setTimeout(300);

    $process->run();

    $output = $process->getOutput().$process->getErrorOutput();

    expect($process->getExitCode())->toBe(1)
        ->and(substr_count($output, 'Feature テストは scenario() ヘルパーを使い、Given-When-Then 形式で記述してください。'))->toBe(8)
        ->and($output)->toContain('ClassStyleFeatureTest.php.inc:11')
        ->and($output)->toContain('PestStyleFeatureTest.php.inc:7');
});
