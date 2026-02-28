# Generic Deployment Checklist Generator

A simple, customizable tool to generate interactive HTML deployment checklists for any project.

## 🚀 Features

- **Interactive Checkboxes**: Track deployment progress in real-time
- **Progress Bar**: Visual progress indicator
- **Local Storage**: Automatically saves progress in browser
- **Responsive Design**: Works on desktop and mobile
- **Customizable**: Easy CSV configuration
- **No Dependencies**: Pure HTML/CSS/JavaScript

## 📋 Quick Start

1. **Configure your deployment**: Edit `checklist_config.csv`
2. **Generate checklist**: Run `python3 generate_checklist.py`
3. **Use checklist**: Open `checklist.html` in your browser

## 📝 Configuration

Edit `checklist_config.csv` to customize for your project:

```csv
type,values
project_name,Your Project Name
release_date,2024-01-15
environment,Production
deployed_by,DevOps Team
deployment_time,2:00 PM EST
release_notes,Major feature release with new authentication system
features,"AUTH-001: New login system,AUTH-002: Password reset,UI-003: Dashboard redesign"
services,"API Gateway,User Service,Database,Frontend App"
health_checks,"https://api.example.com/health,https://app.example.com/status"
commands,"npm run build,npm run migrate,npm run deploy"
bg_commands,"nohup npm run worker > worker.log 2>&1 &"
tasks,"Update DNS,Clear CDN cache,Notify users,Update documentation"
```

## 🔧 Usage

### Basic Usage
```bash
python3 generate_checklist.py
```

### Custom Files
```bash
python3 generate_checklist.py my_config.csv my_checklist.html
```

### CSV Format

| Type | Description | Example |
|------|-------------|---------|
| `project_name` | Project/application name | `My App` |
| `release_date` | Deployment date | `2024-01-15` |
| `environment` | Target environment | `Production` |
| `deployed_by` | Person/team deploying | `DevOps Team` |
| `deployment_time` | Scheduled time | `2:00 PM EST` |
| `release_notes` | Brief description | `Bug fixes and improvements` |
| `features` | Comma-separated features | `"Feature 1,Feature 2,Feature 3"` |
| `services` | Comma-separated services | `"API,Database,Frontend"` |
| `health_checks` | Comma-separated URLs | `"https://api.com/health,https://app.com/status"` |
| `commands` | Management commands | `"npm run build,npm run test"` |
| `bg_commands` | Background commands | `"nohup worker.sh > log 2>&1 &"` |
| `tasks` | Additional tasks | `"Update DNS,Clear cache"` |

## 🎯 Features

### Interactive Elements
- ✅ **Checkboxes**: Mark completed tasks
- 📊 **Progress Bar**: Visual completion tracking
- 💾 **Auto-Save**: Progress saved automatically
- 🔄 **Reset**: Clear all progress button

### Sections Included
- 📋 Release Information
- 🚀 Features/Changes
- ✅ Pre-deployment Checklist
- 🔧 Service Deployment
- 🏥 Health Checks
- ⚡ Management Commands
- 📝 Additional Tasks
- 🎯 Deployment Status

## 🌐 Browser Compatibility

Works in all modern browsers:
- Chrome/Chromium
- Firefox
- Safari
- Edge

## 📁 File Structure

```
deployment-checklist/
├── generate_checklist.py    # Generator script
├── checklist_config.csv     # Configuration template
├── checklist.html          # Generated checklist
└── README.md              # This file
```

## 🔄 Workflow

1. **Before Deployment**:
   - Update `checklist_config.csv` with release details
   - Generate fresh checklist: `python3 generate_checklist.py`
   - Review all items

2. **During Deployment**:
   - Open `checklist.html` in browser
   - Check off completed tasks
   - Monitor progress bar

3. **After Deployment**:
   - Complete final verification
   - Mark deployment status
   - Sign off on completion

## 🎨 Customization

### Styling
The generated HTML includes embedded CSS that can be customized by editing the `generate_checklist.py` file.

### Adding Sections
To add new sections, modify the `generate_html()` function in `generate_checklist.py`.

### Custom Fields
Add new CSV types by extending the configuration parsing logic.

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Check existing documentation
- Review the CSV format examples

---

**Happy Deploying! 🚀**
