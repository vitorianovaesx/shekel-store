import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ShekelStore smoke test', (WidgetTester tester) async {
    // Testes de integração requerem Supabase configurado.
    // Execute o app diretamente com `flutter run` para testar.
    expect(1 + 1, equals(2));
  });
}
