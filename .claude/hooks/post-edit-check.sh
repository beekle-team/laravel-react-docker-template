#!/bin/bash
# Post-edit hook: lint only (tests run on commit)
# Checks PHP and TypeScript files after editing

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0

EXT="${FILE_PATH##*.}"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

case "$EXT" in
  php)
    # Service / Action classes become generic buckets; keep logic in Models.
    if [[ "$FILE_PATH" == *"/app/Services/"* || "$FILE_PATH" == *"/app/Actions/"* ]]; then
      echo "BLOCK: Service / Action classes are not allowed."
      echo "Place DB logic in Eloquent Models, external API logic in Models/Gateway, and shared model behavior in Models/Concerns."
    elif [[ "$FILE_PATH" == *Service.php && "$FILE_PATH" != *"/app/Providers/"*ServiceProvider.php ]]; then
      echo "BLOCK: Service classes are not allowed."
      echo "Place DB logic in Eloquent Models, external API logic in Models/Gateway, and shared model behavior in Models/Concerns."
    fi

    # Enforce Form Request based input validation in controllers.
    if [[ "$FILE_PATH" == *"/app/Http/Controllers/"* ]]; then
      if grep -nE '(\$request->validate\(|request\(\)->validate\()' "$FILE_PATH" >/tmp/form-request-validation-check.txt; then
        echo "BLOCK: Controller input validation must use a Form Request object."
        cat /tmp/form-request-validation-check.txt
        echo "Move rules to app/Http/Requests/** and read validated data with \$request->validated()."
      fi
    fi

    # Run PHPStan on the file
    if [ -f "$PROJECT_ROOT/vendor/bin/phpstan" ]; then
      echo "📋 Analyzing: $(basename "$FILE_PATH")"
      "$PROJECT_ROOT/vendor/bin/phpstan" analyze "$FILE_PATH" --no-progress 2>&1 || true
    fi
    ;;
  ts|tsx)
    if grep -nE '(:| as |<|,|\(|\[|\{|=)\s*any\b|Array<\s*any\s*>|Record<[^>]*,\s*any\s*>' "$FILE_PATH" >/tmp/type-safety-any-check.txt; then
      echo "BLOCK: TypeScript any is not allowed."
      cat /tmp/type-safety-any-check.txt
      echo "Use generated Data types, precise local Props, unknown, or a generic type parameter instead."
    fi

    if [[ "$FILE_PATH" == *"/resources/js/types/"* && "$FILE_PATH" != *"/resources/js/types/generated.d.ts" && "$FILE_PATH" != *"/resources/js/types/vite-env.d.ts" ]]; then
      if grep -nE '^\s*export\s+(interface|type)\s+' "$FILE_PATH" >/tmp/type-safety-manual-types-check.txt; then
        echo "BLOCK: Manual exported types under resources/js/types are not allowed."
        cat /tmp/type-safety-manual-types-check.txt
        echo "Create app/Data/** with #[TypeScript], run php artisan typescript:transform, and use resources/js/types/generated.d.ts."
      fi
    fi

    # Run TypeScript check
    if [ -f "$PROJECT_ROOT/node_modules/.bin/tsc" ]; then
      echo "📋 Type checking: $(basename "$FILE_PATH")"
      # Use tsc with --noEmit to just check types
      cd "$PROJECT_ROOT" && npm run types 2>&1 | head -20 || true
    fi
    ;;
  js|jsx)
    if grep -nE '(:| as |<|,|\(|\[|\{|=)\s*any\b|Array<\s*any\s*>|Record<[^>]*,\s*any\s*>' "$FILE_PATH" >/tmp/type-safety-any-check.txt; then
      echo "BLOCK: TypeScript any is not allowed."
      cat /tmp/type-safety-any-check.txt
      echo "Use generated Data types, precise local Props, unknown, or a generic type parameter instead."
    fi

    # Run Biome lint
    if [ -f "$PROJECT_ROOT/node_modules/.bin/biome" ]; then
      echo "📋 Linting: $(basename "$FILE_PATH")"
      "$PROJECT_ROOT/node_modules/.bin/biome" lint "$FILE_PATH" 2>&1 || true
    fi
    ;;
esac

exit 0
