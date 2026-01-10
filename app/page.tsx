import Link from "next/link";

export default function Page() {
  return (
    <main style={{ padding: 24 }}>
      <h1>Moving Marketplace</h1>
      <p>
        <Link href="/sign-up">Create account</Link>
        {" | "}
        <Link href="/sign-in">Sign in</Link>
      </p>
    </main>
  );
}
