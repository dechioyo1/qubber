import html
import re

def format_xep0393(text):
    """
    Formats raw plain-text into HTML according to XEP-0393: Message Formatting.
    
    Supported directives:
      - Code Blocks: ```code```
      - Inline Code: `code`
      - Blockquotes: > line
      - Bold: *bold*
      - Italic: _italic_
      - Strikethrough: ~strikethrough~
    """
    if not text:
        return ''
    
    # 1. HTML Escape first to prevent XSS / invalid markup
    escaped = html.escape(str(text))
    
    # 2. Extract and protect preformatted code blocks (```code```)
    code_blocks = []
    def save_code_block(match):
        code_blocks.append(match.group(1))
        return f'___CODE_BLOCK_{len(code_blocks)-1}___'
    
    pattern_code_block = re.compile(r'```(?:\w+)?\r?\n?(.*?)\r?\n?```', re.DOTALL)
    text_processed = pattern_code_block.sub(save_code_block, escaped)
    
    # 3. Extract and protect inline code (`code`)
    inline_codes = []
    def save_inline_code(match):
        inline_codes.append(match.group(1))
        return f'___INLINE_CODE_{len(inline_codes)-1}___'
    
    pattern_inline_code = re.compile(r'`([^`\r\n]+)`')
    text_processed = pattern_inline_code.sub(save_inline_code, text_processed)
    
    # 4. Process blockquotes (lines starting with &gt; or >)
    lines = text_processed.splitlines()
    in_quote = False
    quote_acc = []
    output_lines = []
    
    for line in lines:
        if line.startswith('&gt; ') or line.startswith('&gt;'):
            quote_content = line[5:].strip() if line.startswith('&gt; ') else line[4:].strip()
            quote_acc.append(quote_content)
            in_quote = True
        else:
            if in_quote:
                q_text = '<br/>'.join(quote_acc)
                output_lines.append(f'<blockquote style="border-left: 3px solid #3b82f6; margin: 4px 0; padding-left: 8px; color: #94a3b8;">{q_text}</blockquote>')
                quote_acc = []
                in_quote = False
            output_lines.append(line)
    if in_quote:
        q_text = '<br/>'.join(quote_acc)
        output_lines.append(f'<blockquote style="border-left: 3px solid #3b82f6; margin: 4px 0; padding-left: 8px; color: #94a3b8;">{q_text}</blockquote>')
    
    text_processed = '\n'.join(output_lines)
    
    # 5. Process inline spans: Bold (*text*), Italic (_text_), Strikethrough (~text~)
    # Bold: *text*
    text_processed = re.sub(r'(^|\s|\()\s*\*([^\s\*](?:[^\*]*[^\s\*])?)\*(?=$|\s|[.,!?:;\)])', r'\1<b>\2</b>', text_processed)
    # Italic: _text_
    text_processed = re.sub(r'(^|\s|\()\s*_([^\s_](?:[^_]*[^\s_])?)_(?=$|\s|[.,!?:;\)])', r'\1<i>\2</i>', text_processed)
    # Strikethrough: ~text~
    text_processed = re.sub(r'(^|\s|\()\s*~([^\s~](?:[^~]*[^\s~])?)~(?=$|\s|[.,!?:;\)])', r'\1<s>\2</s>', text_processed)
    
    # 6. Restore inline code blocks
    for idx, code in enumerate(inline_codes):
        styled_code = f'<code style="background-color: #334155; color: #f1f5f9; padding: 2px 5px; border-radius: 4px; font-family: monospace;">{code}</code>'
        text_processed = text_processed.replace(f'___INLINE_CODE_{idx}___', styled_code)
        
    # 7. Restore preformatted code blocks
    for idx, code in enumerate(code_blocks):
        styled_block = f'<pre style="background-color: #1e293b; color: #f8fafc; padding: 8px; border-radius: 6px; font-family: monospace; margin: 4px 0; white-space: pre-wrap;"><code>{code}</code></pre>'
        text_processed = text_processed.replace(f'___CODE_BLOCK_{idx}___', styled_block)
        
    # 8. Replace newlines with <br/> (outside <pre> and <blockquote> tags)
    lines_final = text_processed.splitlines()
    res = []
    in_pre = False
    for line in lines_final:
        if '<pre' in line or '<blockquote' in line:
            in_pre = True
        if in_pre:
            res.append(line)
        else:
            res.append(line + '<br/>' if line else '<br/>')
        if '</pre>' in line or '</blockquote>' in line:
            in_pre = False
    
    final_html = ''.join(res)
    if final_html.endswith('<br/>'):
        final_html = final_html[:-5]
    return final_html
