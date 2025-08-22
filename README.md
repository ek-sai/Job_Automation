# Job Automation Workflows

This repository contains N8N workflows for automated job searching and application processing.

## 🚀 Quick Setup

### 1. Environment Variables

Copy the example environment file and fill in your actual values:

```bash
# Copy the example file
cp env.example .env

# Edit the .env file with your actual values
nano .env
```

### 2. Required Environment Variables

#### Database Configuration
```bash
PG_DATABASE=your_actual_database_name
PG_USER=your_actual_username
PG_PASSWORD=your_actual_password
PG_HOST=your_actual_host
PG_PORT=your_actual_port
```

#### API Keys
```bash
# OpenAI API Key (for AI-powered job matching)
OPENAI_API_KEY=sk-your-actual-openai-key-here

# Hunter.io API Key (for finding company emails)
HUNTER_API_KEY=your_actual_hunter_key_here

# Telegram Bot Token (for notifications)
TELEGRAM_BOT_TOKEN=your_actual_bot_token_here
TELEGRAM_CHAT_ID=your_actual_chat_id_here
```

#### N8N Configuration
```bash
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=http://localhost:5678/
```

### 3. Docker Setup

```bash
# Start the services
docker-compose up -d

# Check logs
docker-compose logs -f

# Stop services
docker-compose down
```

### 4. Import Workflows

1. Open N8N at `http://localhost:5678`
2. Import the workflow files:
   - `Final_Working.json` - Main job automation workflow
   - `workflow_with_db.json` - Database-integrated workflow

## 🔒 Security

- **Never commit `.env` files** to version control
- **Use strong passwords** for database access
- **Rotate API keys** regularly
- **Monitor API usage** to prevent abuse

## 📁 File Structure

```
job-automation/
├── .env                    # Environment variables (create from env.example)
├── .gitignore             # Git ignore rules
├── env.example            # Example environment file
├── docker-compose.yml     # Docker services configuration
├── Final_Working.json     # Main workflow
├── workflow_with_db.json  # Database-integrated workflow
├── database_schema.sql    # Database setup script
└── README.md              # This file
```

## 🛠️ Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check database credentials in `.env`
   - Ensure PostgreSQL is running
   - Verify network connectivity

2. **API Key Errors**
   - Verify API keys are correct
   - Check API rate limits
   - Ensure services are accessible

3. **Workflow Import Issues**
   - Check N8N version compatibility
   - Verify JSON file format
   - Check for missing credentials

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review N8N documentation
3. Check API service status pages

## 📝 License

This project is for educational and personal use. Please respect API terms of service and rate limits.
