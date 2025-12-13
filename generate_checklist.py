#!/usr/bin/env python3
"""
Generic Deployment Checklist Generator
=====================================

A simple tool to generate interactive HTML and Markdown deployment checklists from CSV configuration.

Usage:
    python3 generate_checklist.py [config.csv] [output_name]

Default files:
    - Input: checklist_config.csv
    - Output: checklist.html and checklist.md

CSV Format:
    type,values
    project_name,Your Project Name
    features,"Feature 1,Feature 2,Feature 3"
    services,"Service 1,Service 2"
    ...
"""

import csv
import sys
import os

def generate_html(data, project_name):
    """Generate HTML checklist."""
    
    html = f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{project_name} - Deployment Checklist</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            line-height: 1.6;
            color: #333;
        }}
        
        h1 {{
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }}
        
        h2 {{
            color: #34495e;
            border-bottom: 2px solid #3498db;
            padding-bottom: 5px;
            margin-top: 30px;
        }}
        
        h3 {{
            color: #7f8c8d;
            margin-top: 25px;
        }}
        
        .info-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }}
        
        .info-item {{
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }}
        
        .info-label {{
            font-weight: bold;
            color: #2c3e50;
            display: block;
            margin-bottom: 5px;
        }}
        
        .checkbox-item {{
            margin: 12px 0;
            padding: 8px;
            border-radius: 6px;
            transition: background-color 0.2s;
        }}
        
        .checkbox-item:hover {{
            background-color: #f8f9fa;
        }}
        
        input[type="checkbox"] {{
            margin-right: 12px;
            transform: scale(1.3);
            cursor: pointer;
        }}
        
        label {{
            cursor: pointer;
            user-select: none;
        }}
        
        .completed {{
            text-decoration: line-through;
            color: #27ae60;
            background-color: #d5f4e6;
        }}
        
        .status-section {{
            background: linear-gradient(135deg, #ecf0f1, #bdc3c7);
            padding: 20px;
            border-radius: 10px;
            margin-top: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        
        .progress-bar {{
            width: 100%;
            height: 20px;
            background-color: #ecf0f1;
            border-radius: 10px;
            overflow: hidden;
            margin: 15px 0;
        }}
        
        .progress-fill {{
            height: 100%;
            background: linear-gradient(90deg, #3498db, #2ecc71);
            width: 0%;
            transition: width 0.3s ease;
        }}
        
        code {{
            background: #f4f4f4;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'Monaco', 'Consolas', monospace;
            font-size: 0.9em;
        }}
        
        .code-container {{
            position: relative;
            display: inline-block;
            padding-right: 35px;
        }}
        
        .copy-btn {{
            position: absolute;
            right: 5px;
            top: 50%;
            transform: translateY(-50%);
            background: #3498db;
            color: white;
            border: none;
            padding: 2px 6px;
            border-radius: 3px;
            cursor: pointer;
            font-size: 12px;
            opacity: 0.7;
            transition: all 0.3s ease;
        }}
        
        .copy-btn:hover {{
            opacity: 1;
            background: #2980b9;
            transform: translateY(-50%) scale(1.1);
        }}
        
        .copy-btn.copied {{
            background: #27ae60;
            transform: translateY(-50%) scale(1.2);
        }}
        
        .code-container:hover .copy-btn {{
            opacity: 1;
        }}
        
        @media (max-width: 768px) {{
            body {{ padding: 10px; }}
            .info-grid {{ grid-template-columns: 1fr; }}
        }}
    </style>
    <script>
        function updateProgress() {{
            const checkboxes = document.querySelectorAll('input[type="checkbox"]');
            const labels = document.querySelectorAll('label');
            
            let completed = 0;
            
            labels.forEach((label, index) => {{
                if (checkboxes[index] && checkboxes[index].checked) {{
                    label.classList.add('completed');
                    label.parentElement.classList.add('completed');
                    completed++;
                }} else {{
                    label.classList.remove('completed');
                    label.parentElement.classList.remove('completed');
                }}
            }});
            
            const progress = (completed / checkboxes.length) * 100;
            const progressFill = document.querySelector('.progress-fill');
            const progressText = document.querySelector('.progress-text');
            
            if (progressFill) {{
                progressFill.style.width = progress + '%';
            }}
            if (progressText) {{
                progressText.textContent = `${{completed}} of ${{checkboxes.length}} tasks completed (${{Math.round(progress)}}%)`;
            }}
            
            const state = Array.from(checkboxes).map(cb => cb.checked);
            localStorage.setItem('deploymentChecklist', JSON.stringify(state));
        }}
        
        function loadProgress() {{
            const saved = localStorage.getItem('deploymentChecklist');
            if (saved) {{
                const state = JSON.parse(saved);
                const checkboxes = document.querySelectorAll('input[type="checkbox"]');
                checkboxes.forEach((cb, index) => {{
                    if (state[index]) cb.checked = true;
                }});
            }}
            updateProgress();
        }}
        
        function clearProgress() {{
            if (confirm('Are you sure you want to clear all progress?')) {{
                localStorage.removeItem('deploymentChecklist');
                location.reload();
            }}
        }}
        
        function copyToClipboard(text) {{
            const btn = event.target;
            const originalText = btn.textContent;
            
            navigator.clipboard.writeText(text).then(() => {{
                // Success feedback
                btn.textContent = '✓';
                btn.classList.add('copied');
                
                // Reset after 1.5 seconds
                setTimeout(() => {{
                    btn.textContent = originalText;
                    btn.classList.remove('copied');
                }}, 1500);
            }}).catch(() => {{
                // Fallback for older browsers
                const textArea = document.createElement('textarea');
                textArea.value = text;
                document.body.appendChild(textArea);
                textArea.select();
                document.execCommand('copy');
                document.body.removeChild(textArea);
                
                // Success feedback
                btn.textContent = '✓';
                btn.classList.add('copied');
                
                // Reset after 1.5 seconds
                setTimeout(() => {{
                    btn.textContent = originalText;
                    btn.classList.remove('copied');
                }}, 1500);
            }});
        }}
        
        window.onload = loadProgress;
    </script>
</head>
<body>
    <h1>{project_name} - Deployment Checklist</h1>
    
    <div class="progress-bar">
        <div class="progress-fill"></div>
    </div>
    <div class="progress-text" style="text-align: center; margin-bottom: 20px;">0 of 0 tasks completed (0%)</div>
    
    <h2>📋 Release Information</h2>
    <div class="info-grid">
        <div class="info-item">
            <span class="info-label">Release Date</span>
            {data.get('release_date', 'TBD')}
        </div>
        <div class="info-item">
            <span class="info-label">Environment</span>
            {data.get('environment', 'TBD')}
        </div>
        <div class="info-item">
            <span class="info-label">Deployed By</span>
            {data.get('deployed_by', 'TBD')}
        </div>
        <div class="info-item">
            <span class="info-label">Deployment Time</span>
            {data.get('deployment_time', 'TBD')}
        </div>
    </div>'''
    
    # Add features section (non-checklist)
    if data.get('features'):
        html += '''
    
    <h2>🚀 Changes Included</h2>
    <ul>'''
        
        for feature in data['features']:
            html += f'''
        <li>{feature}</li>'''
        
        html += '''
    </ul>'''
    
    # Pre-deployment section
    html += '''
    
    <h2>✅ Pre-Deployment Checklist</h2>
    <h3>Code Preparation</h3>'''
    
    if data.get('pre_deployment'):
        for i, item in enumerate(data['pre_deployment'], 1):
            html += f'''
    <div class="checkbox-item">
        <input type="checkbox" id="pre{i}" onchange="updateProgress()">
        <label for="pre{i}">{item}</label>
    </div>'''
    else:
        # Default items if not configured
        html += '''
    <div class="checkbox-item">
        <input type="checkbox" id="code-review" onchange="updateProgress()">
        <label for="code-review">Code reviewed and approved</label>
    </div>
    <div class="checkbox-item">
        <input type="checkbox" id="tests-pass" onchange="updateProgress()">
        <label for="tests-pass">All tests passing</label>
    </div>'''
    
    # Production PRs section
    if data.get('production_prs'):
        html += '''
    
    <h3>Production PRs</h3>'''
        
        for i, pr_url in enumerate(data['production_prs'], 1):
            pr_number = pr_url.split('/')[-1] if '/' in pr_url else f'PR-{i}'
            html += f'''
    <div class="checkbox-item">
        <input type="checkbox" id="pr{i}" onchange="updateProgress()">
        <label for="pr{i}"><a href="{pr_url}" target="_blank">#{pr_number}</a> - Merged and verified</label>
    </div>'''
    
    # Services deployment section
    if data.get('services'):
        html += '''
    
    <h2>🔧 Deployment Steps</h2>
    <h3>Service Deployment</h3>'''
        
        for i, service in enumerate(data['services'], 1):
            html += f'''
    <div class="checkbox-item">
        <input type="checkbox" id="s{i}" onchange="updateProgress()">
        <label for="s{i}">Deploy {service}</label>
    </div>'''
    
    # Post-deployment verification
    html += '''
    
    <h3>Post-Deployment Verification</h3>'''
    
    if data.get('post_deployment'):
        for i, item in enumerate(data['post_deployment'], 1):
            html += f'''
    <div class="checkbox-item">
        <input type="checkbox" id="post{i}" onchange="updateProgress()">
        <label for="post{i}">{item}</label>
    </div>'''
    else:
        # Default items if not configured
        html += '''
    <div class="checkbox-item">
        <input type="checkbox" id="app-starts" onchange="updateProgress()">
        <label for="app-starts">Application starts successfully</label>
    </div>
    <div class="checkbox-item">
        <input type="checkbox" id="functionality-test" onchange="updateProgress()">
        <label for="functionality-test">Core functionality tested</label>
    </div>
    <div class="checkbox-item">
        <input type="checkbox" id="logs-check" onchange="updateProgress()">
        <label for="logs-check">Logs checked for errors</label>
    </div>'''
    
    # Health checks section
    if data.get('health_checks'):
        html += '''
    
    <h2>🏥 Health Checks</h2>'''
        
        for i, health in enumerate(data['health_checks'], 1):
            html += f'''
    <div class="checkbox-item">
        <input type="checkbox" id="h{i}" onchange="updateProgress()">
        <label for="h{i}">{health}</label>
    </div>'''
    
    # Commands section
    if data.get('commands'):
        html += '''
    
    <h2>⚡ Management Commands</h2>'''
        
        for i, cmd in enumerate(data['commands'], 1):
            escaped_cmd = cmd.replace("'", "\\'")
            html += f'''
    <div class="checkbox-item">
        <input type="checkbox" id="c{i}" onchange="updateProgress()">
        <label for="c{i}">
            <div class="code-container">
                <code>{cmd}</code>
                <button class="copy-btn" onclick="copyToClipboard('{escaped_cmd}')">📋</button>
            </div>
        </label>
    </div>'''
    
    # Background commands section
    if data.get('bg_commands'):
        html += '''
    
    <h3>Background Commands</h3>'''
        
        for i, cmd in enumerate(data['bg_commands'], 1):
            escaped_cmd = cmd.replace("'", "\\'")
            html += f'''
    <div class="checkbox-item">
        <input type="checkbox" id="b{i}" onchange="updateProgress()">
        <label for="b{i}">
            <div class="code-container">
                <code>{cmd}</code>
                <button class="copy-btn" onclick="copyToClipboard('{escaped_cmd}')">📋</button>
            </div>
        </label>
    </div>'''
    
    # Additional tasks section
    if data.get('tasks'):
        html += '''
    
    <h2>📝 Additional Tasks</h2>'''
        
        for i, task in enumerate(data['tasks'], 1):
            html += f'''
    <div class="checkbox-item">
        <input type="checkbox" id="t{i}" onchange="updateProgress()">
        <label for="t{i}">{task}</label>
    </div>'''
    
    # Notes and status section
    html += f'''
    
    <h2>📄 Release Notes</h2>
    <p><em>{data.get('release_notes', 'No additional notes for this release.')}</em></p>
    
    <div class="status-section">
        <h2>🎯 Deployment Status</h2>
        <div style="margin: 20px 0;">
            <div class="checkbox-item">
                <input type="radio" id="success" name="status">
                <label for="success">✅ Deployment Successful</label>
            </div>
            <div class="checkbox-item">
                <input type="radio" id="failed" name="status">
                <label for="failed">❌ Deployment Failed</label>
            </div>
            <div class="checkbox-item">
                <input type="radio" id="rollback" name="status">
                <label for="rollback">🔄 Rolled Back</label>
            </div>
        </div>
        
        <div style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #bdc3c7;">
            <strong>Final Sign-off:</strong> _________________ &nbsp;&nbsp;&nbsp; <strong>Date:</strong> _________
        </div>
        
        <div style="margin-top: 15px; text-align: center;">
            <button onclick="clearProgress()" style="background: #e74c3c; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer;">
                Clear All Progress
            </button>
        </div>
    </div>
</body>
</html>'''
    
    return html

def generate_markdown(data, project_name):
    """Generate Markdown checklist for Git repositories."""
    
    md = f'''# {project_name} - Deployment Checklist

## 📋 Release Information

- **Release Date**: {data.get('release_date', 'TBD')}
- **Environment**: {data.get('environment', 'TBD')}
- **Deployed By**: {data.get('deployed_by', 'TBD')}
- **Deployment Time**: {data.get('deployment_time', 'TBD')}

'''
    
    # Add features section (non-checklist)
    if data.get('features'):
        md += '''## 🚀 Changes Included

'''
        for feature in data['features']:
            md += f'- {feature}\n'
        md += '\n'
    
    # Pre-deployment section
    md += '''## ✅ Pre-Deployment Checklist

### Code Preparation
'''
    
    if data.get('pre_deployment'):
        for item in data['pre_deployment']:
            md += f'- [ ] {item}\n'
    else:
        # Default items if not configured
        md += '''- [ ] Code reviewed and approved
- [ ] All tests passing
- [ ] Database/system backup created
'''
    
    # Production PRs section
    if data.get('production_prs'):
        md += '''
### Production PRs
'''
        for i, pr_url in enumerate(data['production_prs'], 1):
            pr_number = pr_url.split('/')[-1] if '/' in pr_url else f'PR-{i}'
            md += f'- [ ] [#{pr_number}]({pr_url}) - Merged and verified\n'
    
    md += '\n'
    
    # Services deployment section
    if data.get('services'):
        md += '''## 🔧 Deployment Steps

### Service Deployment
'''
        for service in data['services']:
            md += f'- [ ] Deploy {service}\n'
        md += '\n'
    
    # Post-deployment verification
    md += '''### Post-Deployment Verification
'''
    
    if data.get('post_deployment'):
        for item in data['post_deployment']:
            md += f'- [ ] {item}\n'
    else:
        # Default items if not configured
        md += '''- [ ] Application starts successfully
- [ ] Core functionality tested
- [ ] Performance within acceptable limits
- [ ] Logs checked for errors
'''
    
    md += '\n'
    
    # Health checks section
    if data.get('health_checks'):
        md += '''## 🏥 Health Checks

'''
        for health in data['health_checks']:
            md += f'- [ ] {health}\n'
        md += '\n'
    
    # Commands section
    if data.get('commands'):
        md += '''## ⚡ Management Commands

'''
        for cmd in data['commands']:
            md += f'- [ ] `{cmd}`\n'
        md += '\n'
    
    # Background commands section
    if data.get('bg_commands'):
        md += '''### Background Commands

'''
        for cmd in data['bg_commands']:
            md += f'- [ ] `{cmd}`\n'
        md += '\n'
    
    # Additional tasks section
    if data.get('tasks'):
        md += '''## 📝 Additional Tasks

'''
        for task in data['tasks']:
            md += f'- [ ] {task}\n'
        md += '\n'
    
    # Notes and status section
    md += f'''## 📄 Release Notes

{data.get('release_notes', 'No additional notes for this release.')}

## 🎯 Deployment Status

- [ ] ✅ Deployment Successful
- [ ] ⚠️ Partial Success (with issues)
- [ ] ❌ Deployment Failed
- [ ] 🔄 Rolled Back

**Final Sign-off**: _________________ **Date**: _________

---

*Generated by [Generic Deployment Checklist Generator](https://github.com/your-repo/deployment-checklist)*
'''
    
    return md

def main():
    """Main function to handle command line arguments and generate checklists."""
    
    # Parse command line arguments
    csv_file = sys.argv[1] if len(sys.argv) > 1 else "checklist_config.csv"
    output_name = sys.argv[2] if len(sys.argv) > 2 else "checklist"
    
    print("🚀 Generic Deployment Checklist Generator")
    print("=" * 40)
    
    if not os.path.exists(csv_file):
        print(f"❌ Error: {csv_file} not found!")
        return 1
    
    # Read CSV data
    data = {}
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                type_val = row['type'].strip()
                values = row['values'].strip()
                
                if type_val in ['features', 'services', 'health_checks', 'commands', 'bg_commands', 'tasks', 'pre_deployment', 'post_deployment', 'production_prs']:
                    data[type_val] = [v.strip() for v in values.split(',') if v.strip()]
                else:
                    data[type_val] = values
    except Exception as e:
        print(f"❌ Error reading CSV file: {e}")
        return 1
    
    project_name = data.get('project_name', 'Deployment Project')
    
    # Generate HTML
    html_content = generate_html(data, project_name)
    html_file = f"{output_name}.html"
    
    try:
        with open(html_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"✅ Generated HTML: {html_file}")
    except Exception as e:
        print(f"❌ Error writing HTML file: {e}")
        return 1
    
    # Generate Markdown
    md_content = generate_markdown(data, project_name)
    md_file = f"{output_name}.md"
    
    try:
        with open(md_file, 'w', encoding='utf-8') as f:
            f.write(md_content)
        print(f"✅ Generated Markdown: {md_file}")
    except Exception as e:
        print(f"❌ Error writing Markdown file: {e}")
        return 1
    
    print(f"📄 Configuration: {csv_file}")
    print(f"🌐 Interactive: Open {html_file} in browser")
    print(f"📝 Git-friendly: Use {md_file} in repositories")
    
    return 0

if __name__ == "__main__":
    exit(main())
