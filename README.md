# CodePeer-Review

CodePeer-Review is a web platform developed with Ruby on Rails that allows users to create, edit, and view projects, repositories, and code snippets. The functionalities are similar to GitHub, with project files stored on AWS S3. The frontend uses JavaScript to ensure a good user experience.

## Features

- **Account Management:**
  - User registration and login with Devise.
  - OAuth authentication support with Google, GitHub, and GitLab.

- **Project Management:**
  - Create, view, edit, and delete projects.
  - Upload and manage project files.
  - Automatic generation of the README.md file.

- **Integrated Code Editor:**
  - Use of Monaco Editor for code editing.
  - Support for various programming languages (.py, .c, .cpp, .rb, .rs, .txt, .md, .html, .css, .js, etc.).
  - Syntax highlighting and multi-language support.

- **AWS S3 Storage:**
  - Upload and manage files on AWS S3 for each project.

## Installation

Follow these steps to set up the project locally:

### Prerequisites

- Ruby 2.7.0 or higher
- Rails 6.1.7.8
- Node.js and Yarn
- AWS S3 account

### Clone the repository

```bash
git clone https://github.com/your-username/codepeer-review.git
cd codepeer-review
```

### Install dependencies

```bash
bundle install
yarn install
```

### Configure the database

Run the database migrations:

```bash
rails db:create
rails db:migrate
```

### Configure AWS S3

Create a `.env` file in the root of the project and add your AWS credentials:
```bash 
touch .env
```

```env
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=your_region
AWS_BUCKET=your_bucket_name
```

### Configure OAuth credentials

Add the OAuth credentials for Google, GitHub, and GitLab to the `.env` file:

```env
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret
GITLAB_CLIENT_ID=your_gitlab_client_id
GITLAB_CLIENT_SECRET=your_gitlab_client_secret
```

### Start the application

```bash
rails server
```

Open your browser and navigate to `http://localhost:3000`, or `http://127.0.0.1:3000`, to see the application in action.
