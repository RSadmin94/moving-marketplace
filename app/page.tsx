"use client";

import Link from "next/link";
import { SignedIn, SignedOut, UserButton, useUser } from "@clerk/nextjs";
import { useRouter } from "next/navigation";
import { useEffect } from "react";

function HomeContent() {
  const { user, isLoaded } = useUser();
  const router = useRouter();

  useEffect(() => {
    if (isLoaded && user) {
      const role = user.publicMetadata?.role as string | undefined;
      if (!role) {
        router.push("/choose-role");
      }
    }
  }, [user, isLoaded, router]);

  if (!isLoaded) {
    return (
      <main style={{ padding: 24, fontFamily: "system-ui" }}>
        <h1>Moving Marketplace</h1>
        <p>Loading...</p>
      </main>
    );
  }

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

export default function Page() {
  return <HomeContent />;
}
