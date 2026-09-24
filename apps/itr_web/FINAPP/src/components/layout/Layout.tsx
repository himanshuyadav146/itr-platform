import MainContainer from "./MainContainer";
import Header from "./Header";
import Footer from "./Footer";
import { Outlet } from "react-router-dom";
const Layout = () => {
  return (
    <MainContainer>
      <div className="flex flex-col min-h-screen">
        <Header />
        {/* Scrollable Content */}
        <main className="flex-1 overflow-y-auto px-0 py-0">
            <Outlet />
          </main>

        <Footer />
      </div>
    </MainContainer>
  );
};

export default Layout;
