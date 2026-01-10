import Link from "next/link";

export default function Page() {
  return (
    <main style={{ padding: 24, fontFamily: "system-ui, -apple-system, Segoe UI, Roboto, Arial" }}>
      <h1>Moving Marketplace</h1>
      <ul>
        <li><Link href="/sign-up">Create account</Link></li>
        <li><Link href="/sign-in">Sign in</Link></li>
      </ul>
    </main>
  );
}
