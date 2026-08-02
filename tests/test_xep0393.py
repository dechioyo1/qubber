import unittest
from PySide6.QtCore import QCoreApplication
import sys

from xep0393_formatter import format_xep0393
from chat_model import ChatModel

class TestXEP0393(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not QCoreApplication.instance():
            cls.app = QCoreApplication(sys.argv)

    def test_bold_formatting(self):
        res = format_xep0393("This is *bold text* here.")
        self.assertIn("<b>bold text</b>", res)

    def test_italic_formatting(self):
        res = format_xep0393("This is _italic text_ here.")
        self.assertIn("<i>italic text</i>", res)

    def test_strikethrough_formatting(self):
        res = format_xep0393("This is ~strikethrough text~ here.")
        self.assertIn("<s>strikethrough text</s>", res)

    def test_inline_code_formatting(self):
        res = format_xep0393("Use `print('hello')` in python.")
        self.assertIn("<code", res)
        self.assertIn("print(&#x27;hello&#x27;)", res)

    def test_code_block_formatting(self):
        sample = "```python\ndef test():\n    return *not bold*\n```"
        res = format_xep0393(sample)
        self.assertIn("<pre", res)
        self.assertIn("def test():", res)
        self.assertNotIn("<b>not bold</b>", res)

    def test_blockquote_formatting(self):
        sample = "> Quote line 1\n> Quote line 2"
        res = format_xep0393(sample)
        self.assertIn("<blockquote", res)
        self.assertIn("Quote line 1", res)

    def test_html_security_escaping(self):
        sample = "<script>alert('xss')</script> *safe*"
        res = format_xep0393(sample)
        self.assertNotIn("<script>", res)
        self.assertIn("&lt;script&gt;", res)
        self.assertIn("<b>safe</b>", res)

    def test_chat_model_formatted_body_role(self):
        model = ChatModel()
        model.add_message('me', 'Hello *world*', '12:00', True)
        idx = model.index(0, 0)
        formatted = model.data(idx, model.FormattedBodyRole)
        self.assertIn("<b>world</b>", formatted)
        # Raw body must remain unmodified
        self.assertEqual(model.data(idx, model.BodyRole), 'Hello *world*')

if __name__ == '__main__':
    unittest.main()
