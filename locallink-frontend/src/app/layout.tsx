import "./globals.css";
import TopBar from "../components/layout/TopBar";
import BottomNav from "../components/navigation/BottomNav";

export const metadata = {
  title: "LocalLink",
  description: "Local jobs & activities",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ru">
      <body className="bg-gray-50 text-slate-800">
        <TopBar />
        <main className="max-w-6xl mx-auto px-3 md:px-6 pt-3 pb-[100px]">
          {children}
        </main>
        <BottomNav />
      </body>
    </html>
  );
}
