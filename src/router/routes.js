import AuthLayout from 'layouts/Auth';
// import SplashPage from 'pages/Splash';
import LoginPage from 'pages/Login';
import ResetPWPage from 'pages/ResetPW';

import MainLayout from 'layouts/MainLayout';
import Home from 'pages/Home';                    //  Installer lists home
import DocumentPage from 'pages/Document';        //  View pdf document
import StatementPage from 'pages/Statement';      //  Subcontractor statement submit/cancel
import UploadPage from 'pages/Upload';            //  Upload document
import SignPage from 'pages/SignPad';             //  Signature pad
import ContactPage from 'pages/Contact';          //  Contact Us
import FAQPage from 'pages/FAQ';                  //  FAQ
import Error404 from 'pages/Error404';

const routes = [
  {
    path: '/',
    component: AuthLayout,
    children: [
      { path: '', component: LoginPage },
      { path: 'login', component: LoginPage },
      { path: 'resetPW', component: ResetPWPage }
    ]
  },
  {
    path: '/app',
    component: MainLayout,
    children: [
      { path: 'home/:page', component: Home },
      { path: 'showdocument', component: DocumentPage },
      { path: 'showstatement', component: StatementPage },  // *************** contractor statement + need invoice or just expand?
      { path: 'upload', component: UploadPage },
      { path: 'signpad', component: SignPage },
      { path: 'contact', component: ContactPage },
      { path: 'faq', component: FAQPage }
    ]
  },
  {
    path: '/:catchAll(.*)*',
    component: Error404
  }
]

export default routes
