import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isProtectedRoute = createRouteMatcher([
  "/shipper(.*)",
  "/mover(.*)",
]);

export default clerkMiddleware((auth, req) => {
  // ✅ FORCE Clerk to handle auth redirects for protected routes
  if (isProtectedRoute(req)) {
    auth().protect(); // redirects unauth users to /sign-in automatically
  }
});

export const config = {
  matcher: [
    "/((?!.*\\..*|_next).*)",
    "/",
    "/(api|trpc)(.*)",
  ],
};