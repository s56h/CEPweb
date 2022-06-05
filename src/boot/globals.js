import { reactive } from 'vue'

//export default boot(async ({ app }) => {
export const globalData = reactive({
  // ************************************* DELETE ************************************************
  //    App-wide globals

  userEmail: '',                            //    login id
  sessionKey: 'xyz',                           //    login session id
  environment: 'default',                          //    'test' or 'prod'

  installerId: 3344,                        //    installer database key
  installerName: '',                        //    installer full name
  installerCompanyId: 0,                    //    installer company id

  //    Checklist globals

  checkList: [],                            //    checklist list array
  checkListId: 0,                           //    checklist item database key
  checkType: '',                            //    checklist item check type
  documentName: '',                         //    checklist item document name
  documentStatus: '',                       //    checklist item document name
  hasExpiry: false,                         //    checklist item expiry date present flag
  listRow: 0,                               //    checklist selected row index

  //    Statement globals

  statementFilename: '',                    //    full filename of contractor statement document
  statementStatus: '',                      //    '' or '?'
  statementData: null,                      //    statement attributes object

  //    Invoice globals

  invoiceId: 0,                             //    'unknown', 'saved' or 'none'
  invoiceLabel: '',                         //    full filename of contractor statement document
  invoiceStatus: '',                        //    'paid', 'submitted' or 'rejected'?

  //    Signature globals

  signatureStatus: 'unknown'               //    'unknown', 'none' or 'saved'

})
