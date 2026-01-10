import Link from "next/link";

export default function Page() {
  return (
    <main style={{ padding: 24, fontFamily: "system-ui" }}>
      <h1>Moving Marketplace</h1>
      <p>Welcome to the Moving Marketplace</p>

      <p style={{ marginTop: 16 }}>
        <Link href="/sign-up">Create account</Link>
        {" | "}
        <Link href="/sign-in">Sign in</Link>
      </p>
    </main>
  );
}
