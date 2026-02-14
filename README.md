# Finance Vision MA — Local dev server

This workspace contains a static frontend. For secure use of your API key, run the small Express server which will read `.env` and provide `/config` to the client.

Steps:

1. Install dependencies:

```bash
npm install
```

2. Start the server:

```bash
npm start
```

3. Open in browser:

http://localhost:3000/index.html

Notes:
- Keep `.env` secret. It's ignored by `.gitignore`.
- This approach is for local development only. For production, never expose secret keys to client-side code; proxy requests server-side.
