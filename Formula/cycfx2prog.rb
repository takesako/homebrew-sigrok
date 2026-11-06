class Cycfx2prog < Formula
  desc "Cypress FX2 programmer: download 8051 program into the FX2(LP) board"
  homepage "https://www.triplespark.net/elec/periph/USB-FX2/software/"
  url "https://www.triplespark.net/elec/periph/USB-FX2/software/cycfx2prog-0.47.tar.gz"
  mirror "https://web.archive.org/web/2024id_/https://www.triplespark.net/elec/periph/USB-FX2/software/cycfx2prog-0.47.tar.gz"
  sha256 "0e2669c11e81b271d26f96f252e936d81b4847dd5f47e50d17003c5330f74a36"
  license "GPL-2.0-only"
  revision 1

  livecheck do
    url :homepage
    regex(/href=.*?cycfx2prog[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  depends_on "libusb-compat"

  # Fix link order and add EEPROM programming (eeprom:AX and iic:FILE commands)
  patch :DATA

  def install
    system "make", "CC=#{ENV.cxx}"
    bin.install "cycfx2prog"
  end

  test do
    assert_match "eeprom:AX", shell_output("#{bin}/cycfx2prog --help 2>&1")
  end
end

__END__
--- cycfx2prog-0.47/Makefile
+++ cycfx2prog-0.47-new/Makefile
@@ -9,7 +9,7 @@
 
 # NOTE: Also add sources to the "dist:" target!
 cycfx2prog: cycfx2prog.o cycfx2dev.o
-	$(CC) $(LDFLAGS) cycfx2prog.o cycfx2dev.o -o cycfx2prog
+	$(CC) cycfx2prog.o cycfx2dev.o -o cycfx2prog $(LDFLAGS)
 
 clean:
 	-rm -f *.o
--- cycfx2prog-0.47/cycfx2dev.cc
+++ cycfx2prog-0.47-new/cycfx2dev.cc
@@ -328,7 +328,7 @@
 		size_t bs=dend-d;
 		if(bs>chunk_size)  bs=chunk_size;
 		size_t dl_addr=addr+(d-data);
-		int rv=usb_control_msg(usbhdl,0x40,0xa0,
+		int rv=usb_control_msg(usbhdl,0x40,AX,
 			/*addr=*/dl_addr,0,
 			/*buf=*/(char*)d,/*size=*/bs,
 			/*timeout=*/1000/*msec*/);
@@ -358,7 +358,7 @@
 		size_t bs=dend-d;
 		if(bs>chunk_size)  bs=chunk_size;
 		size_t rd_addr=addr+(d-data);
-		int rv=usb_control_msg(usbhdl,0xc0,0xa0,
+		int rv=usb_control_msg(usbhdl,0xc0,AX,
 			/*addr=*/rd_addr,0,
 			/*buf=*/(char*)d,/*size=*/bs,
 			/*timeout=*/1000/*msec*/);
@@ -488,7 +488,7 @@
 int CypressFX2Device::ProgramBinFile(const char *path,size_t start_addr)
 {
 	if(!IsOpen())
-	{  fprintf(stderr,"ProgramIHexFile: Not connected!\n");  return(1);  }
+	{  fprintf(stderr,"ProgramBinFile: Not connected!\n");  return(1);  }
 	
 	int fd=::open(path,O_RDONLY);
 	if(fd<0)
@@ -496,7 +496,7 @@
 		return(2);  }
 	
 	int n_errors=0;
-	const size_t buflen=1024;
+	const size_t buflen=64;
 	char buf[buflen];
 	size_t addr=start_addr;
 	for(;;)
--- cycfx2prog-0.47/cycfx2dev.h
+++ cycfx2prog-0.47-new/cycfx2dev.h
@@ -98,6 +98,9 @@
 		int CtrlMsg(unsigned char requesttype,
 			unsigned char request,int value,int index,
 			const unsigned char *ctl_buf=NULL,size_t ctl_buf_size=0);
+
+		// set AX to 0xA2 (small EEPROM) or 0xA9 (large EEPROM)
+		int AX = 0xA0; // default AX is 0xA0 (internal RAM)
 };
 
 #endif  /* _CYCFX2PROG_CYCFX2DEVICE_ */
--- cycfx2prog-0.47/cycfx2prog.cc
+++ cycfx2prog-0.47-new/cycfx2prog.cc
@@ -156,6 +156,8 @@
 		"  delay:NN       make a delay for NN msec\n"
 		"  set:ADR,VAL    set byte at address ADR to value VAL\n"
 		"  dram:ADR,LEN   dump RAM content: LEN bytes starting at ADR\n"
+		"  eeprom:AX      set EEPROM request AX to 0xA9 or 0xA2 (default:0xA0 is RAM)\n"
+		"  iic:FILE       program to the EEPROM; File is a firmware binary file (.iic)\n"
 		"  dbulk:EP,L[,N] bulk read N (default: 1) buffers of size L from endpoint\n"
 		"                 EP (1,2,4,6,8) and dump them; L<0 to allow short reads\n"
 		"  sbulk:EP,STR   send string STR as bulk message to endpoint EP (1,2,4,6,8)\n"
@@ -319,13 +321,26 @@
 			
 			const char *file=a[0];
 			if(!file)
-			{  fprintf(stderr,"Command \"dl\" requires file to download.\n");
+			{  fprintf(stderr,"Command \"prg\" requires file to download.\n");
 				++errors;  }
 			else
 			{
 				fprintf(stderr,"Programming 8051 using \"%s\".\n",file);
 				errors+=cycfx2.ProgramIHexFile(file);
 			}
+		} else if(!strcmp(cmd,"iic")) {
+			if(cycfx2.AX == 0xA0)
+			{  fprintf(stderr,"Command \"iic\" requires before eeprom:0xA9(or 0xA2)\n");
+				++errors;  }
+			const char *file=a[0];
+			if(!file)
+			{  fprintf(stderr,"Command \"iic\" requires file to download.\n");
+				++errors;  }
+			else
+			{
+				fprintf(stderr,"Programming EEPROM using \"%s\".\n",file);
+				errors+=cycfx2.ProgramBinFile(file);
+			}
 		}
 		else if(!strcmp(cmd,"delay"))
 		{
@@ -354,6 +369,12 @@
 			errors+=cycfx2.ReadRAM(adr,buf,len);
 			HexDumpBuffer(stdout,buf,len,/*with_ascii=*/1);
 			if(buf)  free(buf);
+		}
+		else if(!strcmp(cmd,"eeprom"))
+		{
+			if(a[0] && *a[0])
+			{  cycfx2.AX=strtol(a[0],NULL,0);  }
+			fprintf(stderr,"EEPROM: set AX to 0x%2x\n", cycfx2.AX);
 		}
 		else if(!strcmp(cmd,"set"))
 		{
