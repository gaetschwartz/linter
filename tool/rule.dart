// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:linter/src/utils.dart';
import 'package:path/path.dart' as path;

import '../test/test_constants.dart';

/// Generates rule and rule test stub files (into `src/rules` and `test_data/rules`
/// respectively), as well as the rule index (`rules.dart`).
void main(List<String> args) {
  var parser = ArgParser()
    ..addOption('out', abbr: 'o', help: 'Specifies project root.')
    ..addOption(
      'name',
      abbr: 'n',
      help: 'Specifies lower_underscore rule name.',
      mandatory: true,
    );

  ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, err.message);
    return;
  }

  var outDir = options['out'] ?? '.';
  var d = Directory(outDir as String);
  if (!d.existsSync()) {
    printToConsole("Directory '${d.path}' does not exist");
    return;
  }

  var ruleName = options['name'];

  if (ruleName == null) {
    printUsage(parser);
    return;
  }

  // Generate rule stub.
  generateRule(ruleName as String, outDir: outDir);
}

String get _thisYear => DateTime.now().year.toString();

String capitalize(String s) => s.substring(0, 1).toUpperCase() + s.substring(1);

void generateRule(String ruleName, {String? outDir}) {
  // Generate rule stub.
  generateStub(ruleName, path.join('lib', 'src', 'rules'), _generateClass,
      outDir: outDir);

  // Generate test stub.
  generateStub(ruleName, ruleTestDir, _generateTest, outDir: outDir);

  // Update rule registry.
  updateRuleRegistry(ruleName);

  printToConsole('A unit test has been stubbed out in:');
  printToConsole('  $ruleTestDir/${ruleName}_test.dart');
}

void generateStub(String ruleName, String stubPath, Generator generator,
    {String? outDir}) {
  var (:file, :contents) = generator(ruleName, toClassName(ruleName));
  if (outDir != null) {
    var outPath = path.join(outDir, stubPath, file);
    var outFile = File(outPath);
    if (outFile.existsSync()) {
      printToConsole('Warning: stub already exists at $outPath; skipping');
      return;
    }
    printToConsole('Writing to $outPath');
    outFile.writeAsStringSync(contents);
  } else {
    printToConsole(contents);
  }
}

void printUsage(ArgParser parser, [String? error]) {
  var message = error ?? 'Generates rule stubs.';

  stdout.write('''$message
Usage: rule
${parser.usage}
''');
}

String toClassName(String ruleName) =>
    ruleName.split('_').map(capitalize).join();

void updateRuleRegistry(String ruleName) {
  printToConsole("Don't forget to update lib/src/rules.dart with a line like:");
  printToConsole('  ..register(${toClassName(ruleName)}())');
  printToConsole('and add your rule to `example/all.yaml`.');
}

GeneratedFile _generateClass(String ruleName, String className) => (
      file: '$ruleName.dart',
      contents: """
// Copyright (c) $_thisYear, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r' ';

const _details = r'''
**DO** ...

**BAD:**
```dart

```

**GOOD:**
```dart

```

''';

class $className extends LintRule {
  static const LintCode code = LintCode(
      '$ruleName', '<add problem message here>',
      correctionMessage: '<add correction message here>');

  $className()
      : super(
            name: '$ruleName',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addSimpleIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // TODO: implement
  }
}
"""
    );

GeneratedFile _generateTest(String libName, String className) => (
      file: '${libName}_test.dart',
      contents: '''
// Copyright (c) $_thisYear, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

// TODO: add to all.dart

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(${className}Test);
  });
}

@reflectiveTest
class ${className}Test extends LintRuleTest {
  @override
  String get lintRule => '$libName';
  
  test_firstTest() async {
    await assertDiagnostics(r\'\'\'
  
\'\'\', [
   lint(0, 0),
    ]);
  }
}
'''
    );

typedef GeneratedFile = ({String file, String contents});

typedef Generator = GeneratedFile Function(String libName, String className);
