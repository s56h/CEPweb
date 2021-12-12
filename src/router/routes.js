import AuthLayout from 'layouts/Auth';
import SplashPage from 'pages/Splash';
import LoginPage from 'pages/Login';
import ResetPWPage from 'pages/ResetPW';
import MainLayout from 'layouts/MainLayout';
import CheckList from 'pages/CheckList';
import ImagePage from 'pages/Image';
import UploadPage from 'pages/Upload';
import ContactPage from 'pages/Contact';
import FAQPage from 'pages/FAQ';
import Error404 from 'pages/Error404';

const routes = [
  {
    path: '/',
    component: AuthLayout,
    children: [
      { path: '', component: SplashPage },
      { path: 'Login', component: LoginPage },
      { path: 'ResetPW', component: ResetPWPage }
    ]
  },
  {
    path: '/app',
    component: MainLayout,
    children: [
      { path: 'CheckList', component: CheckList },
      { path: 'ShowImage', component: ImagePage },
      { path: 'Upload', component: UploadPage },
      { path: 'Contact', component: ContactPage },
      { path: 'FAQ', component: FAQPage }
    ]
  },
  {
    path: '/:catchAll(.*)*',
    component: Error404
  }
]

export default routes
