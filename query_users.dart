import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://xzegdfhcxypnffurfvwc.supabase.co/rest/v1/user_profiles');
  final response = await http.get(
    url,
    headers: {
      'apikey': 'sb_publishable_WqoRr7eEbZnsGKZHctLUJQ_MyIv1B0n',
    },
  );
  // ignore: avoid_print
  print(response.body);
}
