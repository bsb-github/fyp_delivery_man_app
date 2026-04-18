import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resturant_delivery_boy/common/models/response_model.dart';
import 'package:resturant_delivery_boy/common/providers/tracker_provider.dart';
import 'package:resturant_delivery_boy/common/widgets/custom_button_widget.dart';
import 'package:resturant_delivery_boy/features/auth/providers/auth_provider.dart';
import 'package:resturant_delivery_boy/features/order/domain/models/order_model.dart';
import 'package:resturant_delivery_boy/features/order/providers/order_provider.dart';
import 'package:resturant_delivery_boy/features/order/screens/order_details_screen.dart';
import 'package:resturant_delivery_boy/features/order/screens/order_place_screen.dart';
import 'package:resturant_delivery_boy/helper/price_converter_helper.dart';
import 'package:resturant_delivery_boy/localization/language_constrants.dart';
import 'package:resturant_delivery_boy/utill/dimensions.dart';
import 'package:resturant_delivery_boy/utill/images.dart';
import 'package:resturant_delivery_boy/utill/styles.dart';

class CompleteOrderDialogWidget extends StatelessWidget {
  final Function onTap;
  final OrderModel? orderModel;

  final double? totalPrice;

  const CompleteOrderDialogWidget(
      {Key? key, required this.onTap, this.totalPrice, this.orderModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider =
        Provider.of<AuthProvider>(context, listen: false);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          border: Border.all(color: Theme.of(context).primaryColor, width: 0.2),
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Image.asset(Images.money),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Center(
                child: Text(
              getTranslated('do_you_collect_money', context)!,
              style: rubikRegular,
            )),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Center(
                child: Text(
              PriceConverterHelper.convertPrice(context, totalPrice),
              style: rubikMedium.copyWith(
                  color: Theme.of(context).primaryColor, fontSize: 30),
            )),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Row(children: [
              Expanded(
                  child: CustomButtonWidget(
                btnTxt: getTranslated('no', context),
                isShowBorder: true,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(
                            orderModelItem: orderModel,
                          )));
                },
              )),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(child: Consumer<OrderProvider>(
                  builder: (context, orderProvider, child) {
                return CustomButtonWidget(
                  isLoading: orderProvider.isLoading,
                  btnTxt: getTranslated('yes', context),
                  onTap: () async {
                    final ResponseModel response =
                        await orderProvider.updateOrderStatus(
                      token: authProvider.getUserToken(),
                      orderId: orderModel!.id,
                      status: 'delivered',
                    );

                    if (!context.mounted) return;

                    if (response.isSuccess) {
                      await orderProvider.updatePaymentStatus(
                        token: authProvider.getUserToken(),
                        orderId: orderModel!.id,
                        status: 'paid',
                      );

                      final orderCount = await Provider.of<OrderProvider>(
                              context,
                              listen: false)
                          .getOrdersCount();
                      if (orderCount != null &&
                          orderCount.outForDelivery != null &&
                          orderCount.outForDelivery! < 1) {
                        Provider.of<TrackerProvider>(context, listen: false)
                            .stopLocationService();
                      }

                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => OrderPlaceScreen(
                                orderID: orderModel!.id.toString())),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(response.message ??
                                getTranslated('not_found', context)!)),
                      );
                    }
                  },
                );
              })),
            ]),
          ]),
          Positioned(
            right: -Dimensions.paddingSizeLarge,
            top: -Dimensions.paddingSizeLarge,
            child: IconButton(
                padding: const EdgeInsets.all(0),
                icon:
                    const Icon(Icons.clear, size: Dimensions.paddingSizeLarge),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) =>
                          OrderDetailsScreen(orderModelItem: orderModel)));
                }),
          ),
        ]),
      ),
    );
  }
}
