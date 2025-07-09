import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:atomapp/constant.dart';
import 'package:atomapp/paymentcontroller.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:url_launcher/url_launcher.dart';

import 'atom_pay_helper.dart';

class PaymentFinalPage extends StatefulWidget {
  final mode;
  final payDetails;
  final responsehashKey;
  final responseDecryptionKey;

  const PaymentFinalPage(this.mode, this.payDetails, this.responsehashKey,
      this.responseDecryptionKey,
      {super.key});

  @override
  createState() => _PaymentFinalPageState(
      mode, payDetails, responsehashKey, responseDecryptionKey);
}

class _PaymentFinalPageState extends State<PaymentFinalPage> {
  final mode;
  final payDetails;
  final _responsehashKey;
  final _responseDecryptionKey;
  final _key = UniqueKey();
  late InAppWebViewController _controller;
  bool loadComplete = false;
  final Completer<InAppWebViewController> _controllerCompleter =
      Completer<InAppWebViewController>();
  final GlobalKey _keys = GlobalKey();
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    isLoading = true;
    // if (Platform.isAndroid) WebView.platform  = SurfaceAndroidViewController();
  }

  _PaymentFinalPageState(this.mode, this.payDetails, this._responsehashKey,
      this._responseDecryptionKey);
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GetxTapController gcontroller = Get.put(GetxTapController());
    return WillPopScope(
      onWillPop: () => _handleBackButtonAction(context),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 162, 207, 240),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0,
          toolbarHeight: 2,
        ),
        body: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  alignment: Alignment.bottomCenter,
                  image: AssetImage(
                    'assets/images/Untitled21.png',
                  ))),
          child: InAppWebView(
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true, // ✅ Enable JS
              allowFileAccessFromFileURLs: true, // ✅ Allow asset file access
              allowUniversalAccessFromFileURLs: true, // ✅ Avoid CORS issues
              useShouldOverrideUrlLoading: true,
              useOnLoadResource: true,
              allowContentAccess: true,
              // javaScriptCanOpenWindowsAutomatically: true
            ),
            // initialUrl: 'about:blank',
            key: UniqueKey(),
            initialData: InAppWebViewInitialData(
              data: isDebugmode
                  ? '''
                                            <!DOCTYPE html>
                                            <html>
                                            <head>
                                              <meta name="viewport" content="width=device-width, initial-scale=1">
                                              <script src="https://pgtest.atomtech.in/staticdata/ots/js/atomcheckout.js"></script>
                                              <style>
                                                body { margin: 0; padding: 0; width: 100%; height: 100%; }
                                                #payment-form { width: 100%; height: 100%; }
                                              </style>
                                            </head>
                                            <body>
                                              <div id="payment-form"></div>
                                              <script>
                                                function openPay() {
                                                  const options = {
                                                    "atomTokenId": "${gcontroller.atomTokenId}",
                                          "merchId": "${gcontroller.login}",
                                          "custEmail": "test.user@gmail.com",
                                          "custMobile": "8888888888",
                                          "returnUrl": "https://pgtest.atomtech.in/mobilesdk/param",
                                          "userAgent": "mobile_webView"
                                        };
                                        
                                        new AtomPaynetz(options, 'uat');
                                      }
                                      document.addEventListener('DOMContentLoaded', openPay);
                                    </script>
                                  </body>
                                  </html>
                                '''
                  : '''
                          <!DOCTYPE html>
                          <html>
                          <head>
                            <meta name="viewport" content="width=device-width, initial-scale=1">
                            // <script src="https://psa.atomtech.in/staticdata/ots/js/atomcheckout.js"></script>
                            
                            <style>
                              body { margin: 0; padding: 0; width: 100%; height: 100%; }
                              #payment-form { width: 100%; height: 100%; }
                            </style>
                          </head>
                          <body>
                            <div id="payment-form"></div>
                            <script>
                              function openPay() {
                                const options = {
                                  "atomTokenId": "${gcontroller.atomTokenId}",
                        "merchId": "${gcontroller.login}",
                        "custEmail": ""nouser@gmail.com"}",
                        "custMobile": ""9898989898"}",
                        "returnUrl": "https://payment.atomtech.in/mobilesdk/param",
                        "userAgent": "mobile_webView"
                      };
                      new AtomPaynetz(options, 'uat');
                    }
                    document.addEventListener('DOMContentLoaded', openPay);
                  </script>
                </body>
                </html>
              ''',
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
              gcontroller.resetloading();
            },

            onConsoleMessage: (controller, consoleMessage) {
              debugPrint("WebView Console: ${consoleMessage.message}");
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              String url = navigationAction.request.url.toString();
              var uri = navigationAction.request.url!;
              if (url.startsWith("upi://")) {
                debugPrint("upi url started loading");
                try {
                  await launchUrl(uri);
                } catch (e) {
                  _closeWebView(
                      callback: () {},
                      context: context,
                      transactionResult:
                          "Transaction Status = cannot open UPI applications",
                      txid: '',
                      transstatus: 0,
                      paymentname: 'NA',
                      totalamount: '');

                  throw 'custom error for UPI Intent';
                }
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },

            onLoadStop: (controller, url) async {
              debugPrint("onloadstop_url: $url");

              if (url.toString().contains("AIPAYLocalFile")) {
                debugPrint(" AIPAYLocalFile Now url loaded: $url");
                await _controller.evaluateJavascript(
                    source: "${"openPay('" + payDetails}')");

                log('Checking 1 $url');
              }

              if (url.toString().contains('/mobilesdk/param')) {
                log('Checking 2');
                final String response = await _controller.evaluateJavascript(
                    source: "document.getElementsByTagName('h5')[0].innerHTML");
                debugPrint("HTML response : $response");
                var transactionResult = "";
                String transactionid = '';
                int? transactionstatus;
                String paymentmethodname = '';
                String totalamount = '';
                String remark = "";
                if (response.trim().contains("cancelTransaction")) {
                  remark = remark.isEmpty || remark != 'failed'
                      ? "Cancelled"
                      : remark;
                  totalamount = "0";
                  transactionResult = "CANCELLED";
                  transactionstatus = 100;
                } else {
                  final split = response.trim().split('|');
                  final Map<int, String> values = {
                    for (int i = 0; i < split.length; i++) i: split[i]
                  };

                  final splitTwo = values[1]!.split('=');
                  // const platform = MethodChannel('flutter.dev/NDPSAESLibrary');

                  try {
                    final String result =
                        await gcontroller.decrypt(splitTwo[1].toString());
                    //     await platform.invokeMethod('NDPSAESInit', {
                    //   'AES_Method': 'decrypt',
                    //   'text': splitTwo[1].toString(),
                    //   'encKey': _responseDecryptionKey
                    // });
                    var respJsonStr = result.toString();
                    Map<String, dynamic> jsonInput = jsonDecode(respJsonStr);
                    debugPrint("read full respone : $jsonInput");

                    //calling validateSignature function from atom_pay_helper file
                    var checkFinalTransaction =
                        validateSignature(jsonInput, _responsehashKey);

                    if (checkFinalTransaction) {
                      if (jsonInput["payInstrument"]["responseDetails"]
                                  ["statusCode"] ==
                              'OTS0000' ||
                          jsonInput["payInstrument"]["responseDetails"]
                                  ["statusCode"] ==
                              'OTS0551') {
                        debugPrint("Transaction success");
                        transactionid = jsonInput['payInstrument']
                            ['merchDetails']['merchTxnId'];

                        var paymethod = jsonInput['payInstrument']
                                ['payModeSpecificData']['subChannel'][0]
                            .toString();
                        paymentmethodname = 'DC';
                        totalamount = jsonInput['payInstrument']['payDetails']
                                ['totalAmount']
                            .toStringAsFixed(2);
                        remark = "SUCCESS";
                        transactionResult = "SUCCESS";
                        transactionstatus = 200;
                      } else {
                        totalamount = "0";
                        remark = "Failed";
                        debugPrint("Transaction failed");
                        transactionResult = "FAILED";
                        transactionstatus = 300;
                      }
                    } else {
                      totalamount = "0";
                      remark = "Failed";

                      debugPrint("signature mismatched");
                      transactionResult = "FAILED";
                    }
                    debugPrint("Transaction Response : $jsonInput");
                  } on PlatformException catch (e) {
                    debugPrint("Failed to decrypt: '${e.message}'.");
                  }
                }

                _closeWebView(
                    callback: () async {
                      await gcontroller.updatepaymentremark(
                          amount: totalamount,
                          key: _keys,
                          transactionid: gcontroller.transacid,
                          paymentmethod: paymentmethodname,
                          remark: remark);

                      // Get.off(
                      //     () => LandingPage());
                    },
                    context: context,
                    transactionResult: transactionResult,
                    txid: transactionid,
                    transstatus: transactionstatus!,
                    paymentname: paymentmethodname,
                    totalamount: totalamount);
              }
            },
          ),
        ),
      ),
    );
  }

  _closeWebView(
      {required BuildContext context,
      required String transactionResult,
      required int transstatus,
      required String txid,
      required String paymentname,
      required String totalamount,
      required VoidCallback callback}) async {
    callback();
  }

  Future<bool> _handleBackButtonAction(BuildContext context) async {
    debugPrint("_handleBackButtonAction called");
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Do you want to exit the payment ?'),
              actions: <Widget>[
                // ignore: deprecated_member_use
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('No'),
                ),
                // ignore: deprecated_member_use
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pop(); // Close current window
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "Transaction Status = Transaction cancelled")));
                  },
                  child: const Text('Yes'),
                ),
              ],
            ));
    return Future.value(true);
  }
}
