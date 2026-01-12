import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";
import { NextResponse } from "next/server";

const isProtectedRoute = createRouteMatcher(["/shipper(.*)", "/mover(.*)"]);

export default clerkMiddleware((auth, req) => {
  if (!isProtectedRoute(req)) return NextResponse.next();

  const { userId } = auth();
  if (!userId) {
    // Redirect to Clerk sign-in with return path
    const signInUrl = new URL("/sign-in", req.url);
    signInUrl.searchParams.set("redirect_url", req.nextUrl.pathname);
    return NextResponse.redirect(signInUrl);
  }

  return NextResponse.next();
});

export const config = {
  matcher: ["/((?!.*\\..*|_next).*)", "/", "/(api|trpc)(.*)"],
};