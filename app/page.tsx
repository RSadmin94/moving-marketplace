"use client";

import Link from "next/link";
import { SignedIn, SignedOut, UserButton } from "@clerk/nextjs";

export default function Page() {
  return (
    <main style={{ padding: 24, fontFamily: "system-ui" }}>
      <h1>Moving Marketplace</h1>

      <SignedOut>
        <p>
          <Link href="/sign-up">Create account</Link>{" | "}
          <Link href="/sign-in">Sign in</Link>
        </p>
      </SignedOut>

      <SignedIn>
        <p>You are signed in.</p>
        <UserButton afterSignOutUrl="/" />
      </SignedIn>
    </main>
  );
}
