export default async (request, context) => {
  const username = Netlify.env.get("BASIC_AUTH_USER") ?? "admin";
  const password = Netlify.env.get("BASIC_AUTH_PASSWORD");

  // Kein Passwort konfiguriert → Schutz inaktiv (lokale Dev-Previews)
  if (!password) {
    return context.next();
  }

  const authHeader = request.headers.get("authorization");
  if (authHeader) {
    const [type, credentials] = authHeader.split(" ");
    if (type?.toLowerCase() === "basic") {
      const [user, pass] = atob(credentials).split(":");
      if (user === username && pass === password) {
        return context.next();
      }
    }
  }

  return new Response("Zugriff verweigert.", {
    status: 401,
    headers: {
      "WWW-Authenticate": 'Basic realm="M4 Dokumentation"',
    },
  });
};
