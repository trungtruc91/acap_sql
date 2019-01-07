<?php if(isset($products) && count($products)>0){
				// chạy từng product để in sản phẩm
	foreach ($products as $value) { ?>
	<!-- item product -->
	<div class="col-md-3 item-product" title="<?php echo $value['Name'] ?>">
		<figure class="product">
			<!-- picture product -->
			<div class="image">
				<?php 
				$imgs= $value->Pictures()->get()->toArray();
				if(count($imgs)>0){
					$img = $imgs[0]['Url']; ?>
					<img src="{!! url('public/images/') !!}<?php echo  '/'.$img?>" class="clickDetail" onclick="detailProduct(<?php echo $value->id; ?>)">
					<?php 
				}  ?>
				<a data-id='<?php echo $value->id; ?>' data-name="<?php echo $value->Name; ?>" class="add-to-cart">Mua hàng</a>
			</div>
			<!-- Name and price -->
			<figcaption class="clickDetail" onclick="detailProduct(<?php echo $value->id; ?>)">
				<!-- name prodyct -->
				<h3 class="nameProductHome" style = 'overflow: hidden;display: -webkit-box; -webkit-line-clamp: 2;-webkit-box-orient: vertical;'><?php echo $value['Name']; ?></h3>
				<!-- price -->
				<div class="price"><?php
				$price=	$value->Prices()->whereNull('endDate')->get(); 
				if(count($price)>0){
					echo $price[0]['Price']." VNĐ";
				} 
				?> </div>
			</figcaption>
		</figure>
	</div>
	<?php
}?>
<script type="text/javascript" src="{!! url('public/js/Home/product.js') !!}"></script>
<?php 
}else {
	echo "Không tìm thấy sản phẩm nào!";
}
if(isset($seeMore) && $seeMore){
	?>
	<div class='col-md-12 seeMoreProduct' onclick="SeeMore()" id='seeMoreProduct'>
		<button class="btn" style="background: transparent; border:1px solid #e74c3c;">Xem thêm</button>
	</div>
	<script type="text/javascript">
		if(document.getElementById('seeMoreProduct')!=null){
			document.getElementById('seeMoreProduct').style.display = 'block';
		}else{
			var div = document.createElement('div');
			div.setAttribute('class','col-md-12 seeMoreProduct');
			div.setAttribute('style','display:"block";');
			div.setAttribute('id','seeMoreProduct');
			div.setAttribute('onclick','SeeMore()');
			document.appendChild(div);
		}
		function SeeMore(){
			pageList=document.getElementById('pageList-frm');
			pageList.value=parseInt(pageList.value)+1;
			GetProducts();
		};
	</script>
	<?php
}else{
	?>
	<script type="text/javascript">
		if(document.getElementById('seeMoreProduct')!=null){
			document.getElementById('seeMoreProduct').style.display = 'none';
		}
	</script>
	<?php
}
?>
