
volatile int pixel_buffer_start; // global variable
typedef int bool;
#define true 1
#define false 0

void draw_line( int x0, int y0, int x1, int y1, short int line_colour);
void plot_pixel(int x, int y, short int line_color);
void clear_screen();
int abs(int x);
void vsync();
void draw_moving_line();

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
	pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen();
	draw_moving_line();
	while(1);

}
void draw_moving_line(){
	
	int y = 0;
	int y_increment = 1;
	  while (1){
		int y_erase = y;
		
		y = y + y_increment;
        draw_line(40,y_erase,240,y_erase,0x0);
        draw_line(40,y,240,y, 0x07E0); // this line is green
		
		if (y >= 239){
			y_increment = -1;
		}
		else if (y <= 0){
			y_increment = 1;
		}
		
		
        vsync();
    }	
}
// code not shown for clear_screen() and draw_line() subroutines
void vsync(){
    volatile int* status_register =  0xFF203020;
    register int status;

    *status_register = 1; // set B to 1
    status = *(status_register + 3);
    while((status & 0x001) != 0)
    {
        status = *(status_register + 3);
    }
}

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}
//iterate through and draw black pixels

void clear_screen (){
    int i,j;

    for (i = 0; i < 320; i++){
        for (j = 0; j < 240; j++){

            plot_pixel(i,j,0);
        }
    }
}
void draw_line(int x0, int y0, int x1, int y1, short int line_color){
  bool is_steep = abs(y1 - y0) > abs(x1 - x0);
  if(is_steep){
      int a = x0;
      x0 = y0;
      y0 = a;

      a = x1;
      x1 = y1;
      y1 = a;
  }
  if(x0 > x1){
      int a = x0;
      x0 = x1;
      x1 = a;

      a = y0;
      y0 = y1;
      y1 = a;
  }
  int deltaX = x1 - x0;
  int deltaY = abs(y1 - y0);
  int error = (-deltaX)/2;
  int x;
  int y = y0;
  int y_step;
  if(y0 < y1){
    y_step = 1;
  } else{
    y_step = -1;
  }

  for(x = x0; x < x1; ++x){
    if(is_steep)
      plot_pixel(y,x , line_color);
    else
      plot_pixel(x,y , line_color);

    error += deltaY;

    if(error >= 0){
      y += y_step;
      error -= deltaX;
    }
  }
}
int abs(int x)
{
    if(x < 0) return (-1 * x);
    else return x;
}