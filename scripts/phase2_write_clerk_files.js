const fs = require("fs");
const path = require("path");

function write(filePath, content) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, content, { encoding: "utf8" });
  console.log("WROTE", filePath);
}

write(
  "middleware.ts",
  `import { clerkMiddleware } from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  matcher: ["/((?!.*\\\\..*|_next).*)", "/", "/(api|trpc)(.*)"],
};
`
);

write(
  "app/sign-up/[[...sign-up]]/page.tsx",
  `import { SignUp } from "@clerk/nextjs";

export default function Page() {
  return <SignUp />;
}
`
);

write(
  "app/sign-in/[[...sign-in]]/page.tsx",
  `import { SignIn } from "@clerk/nextjs";

export default function Page() {
  return <SignIn />;
}
`
);
